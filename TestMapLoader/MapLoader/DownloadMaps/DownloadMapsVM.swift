//
//  DownloadMapsVM.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import Foundation
import UIKit
import Combine

final class DownloadMapsVM {
    enum ViewModelType {
        case rootRegions
        case subRegions
    }
    
    typealias CellUpdate = (indexPath: IndexPath, status: DownloadMapsCellStatus)
    
    private let parser = RegionsParser()
    private let fileManager = FileProvider()
    
    let downloadManager: DownloadManager

    private var items: [DownloadMapsItem] = []
    private var itemsProgress: [DownloadItemProgressModel] = []
    
    private var bag = Set<AnyCancellable>()
    
    var type: ViewModelType
    
    let reloadTablePublisher = PassthroughSubject<Void, Never>()
    let cellUpdatePublisher = PassthroughSubject<CellUpdate, Never>()
    let storageUpdatePublisher = PassthroughSubject<Void, Never>()
    
    init(downloadManager: DownloadManager, regions: [DownloadMapsItem]? = nil) {
        self.downloadManager = downloadManager
        self.items = regions ?? []
        
        self.type = regions == nil ? .rootRegions : .subRegions

        itemsProgress = downloadManager.getAllItems()
        
        downloadManager.progressPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                
                self.updateProgress(for: value)
            }
            .store(in: &bag)
    }
    
    //MARK: - Start viewModel
    func start() {
        if type == .rootRegions {
            parseRegions()
        }
    }
    
    func title() -> String {
        switch type {
        case .rootRegions:
            "Download Maps"
        case .subRegions:
            items.first?.title ?? ""
        }
    }
    
    //MARK: - Table
    func item(section: Int, row: Int) -> DownloadMapsItem {
        items[section].children[row]
    }
    
    func numbersOfSections() -> Int {
        items.count
    }
    
    func numbersOfRows(section: Int) -> Int {
        items[section].children.count
    }
    
    func name(section: Int) -> String {
        items[section].title
    }
    
    func statusFor(section: Int, row: Int) -> DownloadMapsCellStatus {
        guard let name = item(section: section, row: row).fileName else {
            return .idle
        }
        
        if fileManager.fileExistsInDocuments(fileName: name) {
            return .ready
        }
        
        if let task = itemsProgress.first(where: { $0.fileName == name }) {
            return .loading(progress: task.progress)
        }
        
        return .idle
    }
    
    //MARK: - Actions
    
    func loadTapAction(_ item: DownloadMapsItem) {
        guard let name = item.fileName else {
            return
        }
        if downloadManager.isExistsItem(name) {
            downloadManager.cancel(fileName: name)
        } else {
            downloadManager.enqueue(fileName: name, url: FileURLBuilder.mapsUrl(for: name))
        }
    }
    
    //MARK: - Update progress
    
    private func updateProgress(for progressItem: DownloadItemProgressModel) {
        
        storageUpdatePublisher.send()
        
        switch progressItem.status {
        case .pending, .downloading:
            if let index = self.itemsProgress.firstIndex(where: { $0.fileName == progressItem.fileName }) {
                self.itemsProgress[index] = progressItem
            } else {
                self.itemsProgress.append(progressItem)
            }
        case .finished, .cancelled:
            self.itemsProgress.removeAll(where: { $0.fileName == progressItem.fileName })
        }

        
        for section in self.items.indices {
            if let index = self.items[section].children.firstIndex(where: { $0.fileName == progressItem.fileName }) {
                
                let indexPath = IndexPath(row: index, section: section)
                var status: DownloadMapsCellStatus = .idle
                
                switch progressItem.status {
                case .pending, .downloading:
                    status = .loading(progress: progressItem.progress)
                case .finished:
                    status = .ready
                default:
                    status = .idle
                }
                
                cellUpdatePublisher.send((indexPath: indexPath, status: status))
                break
            }
        }
    }
}

//MARK: - Parser

extension DownloadMapsVM {
    
    private func parseRegions() {
        guard let data = getRegionsData() else {
            return
        }
        
        let regions = parser.parse(data: data)
        
        guard regions.isEmpty == false else {
            return
        }
        
        for region in regions {
            let rootRegion = createItem(region)
            if rootRegion.children.isEmpty == false {
                items.append(rootRegion)
            }
        }
        
        reloadTablePublisher.send()
    }
    
    private func createItem(_ region: RegionParserModel) -> DownloadMapsItem {
        var root = DownloadMapsItem(title: region.translate ?? "No name",
                                      fileName: region.fileName,
                                      isMap: region.isAvailable)

        for child in region.children {
            let childRegion = createItem(child)
            
            if !child.children.isEmpty || child.isAvailable {
                root.children.append(childRegion)
            }
        }
        
        root.children = root.children.sorted(by: { first, second in
            first.title < second.title
        })
        
        return root
    }
    
    private func getRegionsData() -> Data? {
        if let url = Bundle.main.url(forResource: "regions", withExtension: "xml"),
            let data = try? Data(contentsOf: url) {
            
            return data
        }
        
        return nil
    }
}
