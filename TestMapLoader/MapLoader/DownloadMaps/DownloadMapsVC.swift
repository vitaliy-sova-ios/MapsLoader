//
//  DownloadMapsVC.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import UIKit
import Combine

class DownloadMapsVC: UIViewController {
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .infinite, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorInset = .init(top: 0, left: 62, bottom: 0, right: 16)
        table.separatorColor = UIColor(hexString: "#CBC7D1")
        
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 52
        
        table.sectionHeaderHeight = UITableView.automaticDimension
        table.estimatedSectionHeaderHeight = 58
        
        table.register(UINib(nibName: "DownloadMapsCell", bundle: nil), forCellReuseIdentifier: "DownloadMapsCell")
        
        
        return table
    }()

    private var tableHeaderView: DownloadMapsTableHeader? = nil
    
    private let vm: DownloadMapsVM
    
    private var bag = Set<AnyCancellable>()
    
    deinit {
        debugPrint("DEINIT: DownloadMapsVC")
    }
    
    init (viewModel: DownloadMapsVM) {
        vm = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        bindVM()
        
        vm.start()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch vm.type {
        case .rootRegions:
            navigationController?.navigationBar.prefersLargeTitles = true
        default:
            navigationController?.navigationBar.prefersLargeTitles = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateStorageView()
        
        NotificationService.shared.requestPermission()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        resizeTableHeader()
    }

    private func setupUI() {
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        tableView.delegate = self
        tableView.dataSource = self
        
        title = vm.title()
        
        if vm.type == .rootRegions {

            tableHeaderView = .init()
            tableHeaderView?.frame.size = CGSize(width: view.frame.width, height: 108)
            tableHeaderView?.layoutIfNeeded()
            tableView.tableHeaderView = tableHeaderView
        }
    }
    
    private func updateStorageView() {
        let storageInfo = StorageInfoProvider.getInfo()
        tableHeaderView?.storageView
            .configure(freeSpaceText: storageInfo?.formatFreeGB() ?? "-",
                       progress: storageInfo?.usedPercent ?? 0)
    }
    
    private func bindVM() {

        vm.reloadTablePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.tableView.reloadData()
            }
            .store(in: &bag)
        
        vm.cellUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if let cell = self?.tableView.cellForRow(at: value.indexPath) as? DownloadMapsCell {
                    cell.updateStatus(value.status)
                }
                
                guard self?.tableView.window != nil else { return }
                switch value.status {
                    
                case .idle, .ready:
                    self?.tableView.beginUpdates()
                    self?.tableView.endUpdates()
                case .loading(progress: let progress):
                    if progress == 0  {
                        self?.tableView.beginUpdates()
                        self?.tableView.endUpdates()
                    }
                }
            }
            .store(in: &bag)
        
        vm.storageUpdatePublisher
            .throttle(for: 1, scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateStorageView()
            }
            .store(in: &bag)
    }
    
    private func resizeTableHeader() {
        guard let tableHeaderView else { return }
        
        tableHeaderView.setNeedsLayout()
        tableHeaderView.layoutIfNeeded()

        let height = tableHeaderView.systemLayoutSizeFitting(
            CGSize(width: tableView.frame.width,
                   height: UIView.layoutFittingCompressedSize.height)
        ).height

        var frame = tableHeaderView.frame

        frame.size.height = height

        tableHeaderView.frame = frame

        tableView.tableHeaderView = tableHeaderView

    }
}

extension DownloadMapsVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        vm.numbersOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vm.numbersOfRows(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadMapsCell", for: indexPath) as? DownloadMapsCell else {
            return UITableViewCell()
        }
        
        let item = vm.item(section: indexPath.section, row: indexPath.row)
        let status = vm.statusFor(section: indexPath.section, row: indexPath.row)
        
        cell.configure(item, status: status)
        
        cell.onLoadAction = { [weak self] item in
            self?.vm.loadTapAction(item)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = DownloadMapsHeaderView()
        header.configure(text: vm.name(section: section))
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = vm.item(section: indexPath.section, row: indexPath.row)
        
        if item.children.isEmpty == false {

            let vm = DownloadMapsVM(downloadManager: vm.downloadManager, regions: [item])
            let vc = DownloadMapsVC(viewModel: vm)
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

