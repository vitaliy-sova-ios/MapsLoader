//
//  DownloadManager.swift
//  TestMapLoader
//
//  Created by Vitaliy on 10.05.2026.
//

import Foundation
import Combine
import UIKit

// MARK: - Models

enum DownloadItemStatus: String {
    case pending
    case downloading
    case finished
    case cancelled
}

struct DownloadItemModel {
    let fileName: String
    let url: String
    var status: DownloadItemStatus
    var progress: Float
    var taskId: Int?
}

struct DownloadItemProgressModel {
    let fileName: String
    let status: DownloadItemStatus
    let progress: Float
}

// MARK: - DownloadManager

final class DownloadManager: NSObject {

    // MARK: - Public

    let progressPublisher = PassthroughSubject<DownloadItemProgressModel, Never>()

    var backgroundCompletionHandler: (() -> Void)?

    // MARK: - Private state (protected by serial queue)

    private var items: [DownloadItemModel] = []
    private var activeTaskId: Int?

    private let stateQueue = DispatchQueue(
        label: "com.download.manager.state.queue",
        qos: .userInitiated
    )

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(
            withIdentifier: Bundle.main.bundleIdentifier! + ".downloads"
        )

        config.httpMaximumConnectionsPerHost = 1
        config.waitsForConnectivity = true
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false

        return URLSession(configuration: config,
                          delegate: self,
                          delegateQueue: nil)
    }()
    
    private let fileProvider = FileProvider()

    // MARK: - Init

    override init() {
        super.init()
        
        restoreDownloads()
    }
}

// MARK: - Public API

extension DownloadManager {

    func enqueue(fileName: String, url: String) {

        stateQueue.async {

            guard !self.items.contains(where: { $0.fileName == fileName }) else {
                return
            }
            
            let item = DownloadItemModel(fileName: fileName,
                                         url: url,
                                         status: .pending,
                                         progress: 0,
                                         taskId: nil)

            self.items.append(item)

            self.persist(item)
            self.publish(item)
            
            self.startNextIfNeeded()
        }
    }

    func cancel(fileName: String) {

        stateQueue.async {

            guard let index = self.items.firstIndex(where: {
                $0.fileName == fileName
            }) else { return }

            let item = self.items[index]

            if let taskId = item.taskId,
               taskId == self.activeTaskId {

                self.session.getAllTasks { tasks in
                    tasks.first(where: {
                        $0.taskIdentifier == taskId
                    })?.cancel()
                }

                self.activeTaskId = nil
            }

            var removed = self.items.remove(at: index)
            removed.status = .cancelled

            self.persistDelete(fileName)
            self.publish(removed)
            
            self.startNextIfNeeded()
        }
    }

    func isExistsItem(_ fileName: String) -> Bool {

        stateQueue.sync {
            items.contains(where: { $0.fileName == fileName })
        }
    }

    func getAllItems() -> [DownloadItemProgressModel] {

        stateQueue.sync {

            items.map {
                DownloadItemProgressModel(
                    fileName: $0.fileName,
                    status: $0.status,
                    progress: $0.progress
                )
            }
        }
    }
}

// MARK: - Core logic

private extension DownloadManager {

    func startNextIfNeeded() {

        guard activeTaskId == nil else { return }

        guard let index = items.firstIndex(where: {
            $0.status == .pending
        }) else { return }

        let item = items[index]

        guard let url = URL(string: item.url) else { return }

        let task = session.downloadTask(with: url)

        var updated = item
        updated.taskId = task.taskIdentifier
        updated.status = .downloading

        items[index] = updated
        activeTaskId = task.taskIdentifier

        persist(updated)
        publish(updated)
        
        task.resume()
    }
    
    private func restoreDownloads() {

        stateQueue.async {

            // Restore persisted items
            self.items = self.fetchSavedItems()
            for i in self.items {
                print(i.fileName)
            }

            // Ask URLSession about alive tasks
            self.session.getAllTasks { tasks in

                self.stateQueue.async {

                    let activeTasks = tasks.compactMap {
                        $0 as? URLSessionDownloadTask
                    }

                    // Rebind alive tasks
                    for task in activeTasks {

                        guard let index = self.items.firstIndex(where: {
                            $0.taskId == task.taskIdentifier
                        }) else { continue }

                        self.items[index].status = .downloading
                        self.activeTaskId = task.taskIdentifier
                    }

                    // If no active downloads -> restart queue
                    if activeTasks.isEmpty {

                        for index in self.items.indices {

                            if self.items[index].status == .downloading {
                                self.items[index].status = .pending
                                self.items[index].taskId = nil
                            }
                        }

                        self.startNextIfNeeded()
                    }
                }
            }
        }
    }

    func publish(_ item: DownloadItemModel) {

        DispatchQueue.main.async {

            self.progressPublisher.send(
                DownloadItemProgressModel(
                    fileName: item.fileName,
                    status: item.status,
                    progress: item.progress
                )
            )
        }
    }
}

// MARK: - State updates

extension DownloadManager {

    func updateProgress(id: Int, progress: Float) {

        stateQueue.async {

            guard let index = self.items.firstIndex(where: {
                $0.taskId == id
            }) else { return }

            self.items[index].progress = progress
            self.items[index].status = .downloading

            self.publish(self.items[index])
        }
    }

    func complete(id: Int, error: Error?) {

        stateQueue.async {

            guard let index = self.items.firstIndex(where: {
                $0.taskId == id
            }) else { return }

            var item = self.items[index]
            
            if error == nil {
                self.sendNotification(fileName: item.fileName)
            }

            if error == nil {
                item.status = .finished
                item.progress = 1.0
            } else {
                item.status = .cancelled
            }

            self.items.remove(at: index)
            self.activeTaskId = nil

            self.persistDelete(item.fileName)
            self.publish(item)

            self.startNextIfNeeded()
        }
    }
    
    func saveFile(id: Int, fromLocation: URL) {
        
        stateQueue.sync {

            guard let item = self.items.first(where: {
                $0.taskId == id
            }) else { return }
            
            _ = try? self.fileProvider.moveFileToDocuments(from: fromLocation, fileName: item.fileName)
        }
    }
    
    func sendNotification(fileName: String) {
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .active {
                NotificationService.shared.showDownloadFinished(
                    fileName: fileName
                )
            }
        }
    }
}

// MARK: - Saving

private extension DownloadManager {

    func persist(_ item: DownloadItemModel) {

        CoreDataManager.shared.saveTask(
            fileName: item.fileName,
            url: item.url,
            status: item.status.rawValue,
            taskId: Int64(item.taskId ?? 0)
        )
    }

    func persistDelete(_ fileName: String) {
        CoreDataManager.shared.removeTask(byName: fileName)
    }
    
    func fetchSavedItems() -> [DownloadItemModel] {

        CoreDataManager.shared.fetchAll().map {

            DownloadItemModel(
                fileName: $0.fileName ?? "",
                url: $0.url ?? "",
                status: DownloadItemStatus(rawValue: $0.status ?? "") ?? .pending,
                progress: 0,
                taskId: Int($0.taskId)
            )
        }
    }
}

// MARK: - URLSession Delegate

extension DownloadManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        updateProgress(id: downloadTask.taskIdentifier, progress: progress)
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        saveFile(id: downloadTask.taskIdentifier, fromLocation: location)
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        
        complete(id: task.taskIdentifier, error: error)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
        DispatchQueue.main.async {
            
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}
