//
//  DownloadManagerActor.swift
//  TestMapLoader
//
//  Created by Vitaliy on 12.05.2026.
//

import Foundation
import Combine
import UIKit

actor DMActor {
    
    let progressPublisher = DMProgressPublisher()

    private var items: [DownloadItemModel] = []
    private var activeTaskId: Int?

    private let sessionDefault: URLSession
    private let sessionBackground: URLSession
    private let sessionDelegate: DMDelegate

    init(delegate: DMDelegate) {
        self.sessionDelegate = delegate

        // Configure default session
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 1
        config.waitsForConnectivity = true

        self.sessionDefault = URLSession(configuration: config,
                                         delegate: sessionDelegate,
                                         delegateQueue: nil)

        // Configure background session
        let bgConfig = URLSessionConfiguration.background(
            withIdentifier: Bundle.main.bundleIdentifier! + ".downloads"
        )
        bgConfig.httpMaximumConnectionsPerHost = 1
        bgConfig.waitsForConnectivity = true
        bgConfig.sessionSendsLaunchEvents = true
        bgConfig.isDiscretionary = true

        self.sessionBackground = URLSession(configuration: bgConfig,
                                            delegate: sessionDelegate,
                                            delegateQueue: nil)
        
        sessionDelegate.actor = self
        
        Task { @MainActor in
            await getSavedItems()
        }
    }
    
    // MARK: - Notifications
    
    func appMovedToBackground() async {
        await createBackgroundTasks()
    }
    
    func appMovedToForeground() async {
        await restoreDownloads()
    }

    // MARK: - Public API

    func enqueue(fileName: String, url: String) {
        guard !isInQueue(fileName: fileName) else { return }

        let item = DownloadItemModel(fileName: fileName,
                                     url: url,
                                     status: .pending,
                                     progress: 0,
                                     taskId: nil)

        items.append(item)
        
        //save to storage
        saveItem(item)
        //progress
        updateProgress(item)
        
        startNextIfNeeded()
    }

    func cancel(fileName: String) {

        guard let index = items.firstIndex(where: { $0.fileName == fileName }) else { return }

        var item = items[index]
        item.status = .cancelled
        
        if let id = item.taskId, id == activeTaskId {
            sessionDefault.getAllTasks { tasks in
                tasks.first { $0.taskIdentifier == id }?.cancel()
            }
            activeTaskId = nil
        }

        items.remove(at: index)
        
        //remove from storage
        removeItem(item)
        //progress
        updateProgress(item)
        
        startNextIfNeeded()
    }

    func currentItemsProgress() -> [DownloadItemProgressModel] {
        items.map { item in
            DownloadItemProgressModel(fileName: item.fileName,
                                      status: item.status,
                                      progress: item.progress)
        }
    }
    
    func isInQueue(fileName: String) -> Bool {
        items.contains(where: { $0.fileName == fileName })
    }
    
    // MARK: - Save tasks to storage
    
    private func saveItem(_ item: DownloadItemModel) {
        Task {
            await CoreDataManager.shared.saveTask(item)
        }
    }
    
    private func saveAllItems(_ items: [DownloadItemModel]) {
        Task {
            await CoreDataManager.shared.saveTasks(items)
        }
    }
    
    private func removeItem(_ item: DownloadItemModel) {
        Task {
            await CoreDataManager.shared.removeTask(byName: item.fileName)
        }
    }

    // MARK: - Core logic

    private func startNextIfNeeded() {

        guard activeTaskId == nil else { return }

        guard !items.isEmpty else { return }

        let item = items[0]
        guard let url = URL(string: item.url) else { return }

        let task = sessionDefault.downloadTask(with: url)

        items[0].taskId = task.taskIdentifier
        items[0].status = .downloading
        activeTaskId = task.taskIdentifier
        
        sessionDelegate.items = items

        task.resume()
    }
    
    private func getSavedItems() async {
        self.items = await CoreDataManager.shared.fetchAll()
        sessionDelegate.items = items
    }
    
    private func restoreDownloads() async {
        await getSavedItems()
        
        let tasks = await sessionBackground.allTasks
            .compactMap { $0 as? URLSessionDownloadTask }
        
        var map = [Int: Data]()
        for task in tasks {
            if task.state == .running,
                let data = await task.cancelByProducingResumeData() {
                map[task.taskIdentifier] = data
            }
        }
        
        if !map.isEmpty, let first = map.sorted(by: { $0.value.count > $1.value.count }).first {
            if let index = items.firstIndex(where: { $0.taskId == first.key }) {
                
                let task = sessionDefault.downloadTask(withResumeData: first.value)
                activeTaskId = task.taskIdentifier
                
                items[index].taskId = task.taskIdentifier
                saveItem(items[index])
                
                task.resume()
            }
        } else {
            activeTaskId = nil
            startNextIfNeeded()
        }
        
        items.forEach { item in
            updateProgress(item)
        }
    }
    
    private func createBackgroundTasks() async {
        
        let tasks = await sessionDefault.allTasks
            .compactMap { $0 as? URLSessionDownloadTask }
        
        var map = [Int: Data]()
        for task in tasks {
            if let data = await task.cancelByProducingResumeData() {
                map[task.taskIdentifier] = data
            }
        }
        
        var backgroundTasks = [URLSessionDownloadTask]()
        
        for (index, item) in items.enumerated() {
            
            if let id = item.taskId, let data = map[id] {
                
                let task = sessionBackground.downloadTask(withResumeData: data)
                
                items[index].taskId = task.taskIdentifier
                
                backgroundTasks.append(task)
                
            } else if let url = URL(string: item.url) {
                
                let task = sessionBackground.downloadTask(with: url)
                
                items[index].taskId = task.taskIdentifier
                
                backgroundTasks.append(task)
            }
        }

        saveAllItems(items)
        
        sessionDelegate.items = items
        
        backgroundTasks.forEach { $0.resume() }
    }

    // MARK: - Progress

    fileprivate func updateProgress(taskId: Int, progress: Float) {

        guard let index = items.firstIndex(where: { $0.taskId == taskId }) else { return }

        items[index].progress = progress
        items[index].status = .downloading

        updateProgress(items[index])
    }
    
    fileprivate func updateProgress(_ item: DownloadItemModel) {
        Task { @MainActor in
            await progressPublisher.emitProgress(item.progressModel)
        }
    }

    fileprivate func complete(taskId: Int, error: Error?, session: URLSession) {

        guard let index = items.firstIndex(where: { $0.taskId == taskId }) else { return }

        var item = items[index]

        if error == nil {
            item.status = .finished
            item.progress = 1.0
        } else {
            item.status = .cancelled
        }

        items.remove(at: index)
        activeTaskId = nil
        
        //remove from storage
        removeItem(item)
        //progress
        updateProgress(item)
        
        if session == sessionDefault {
            startNextIfNeeded()
        } else if items.isEmpty {
            Task { @MainActor in
                NotificationService.shared.showDownloadFinished()
            }
        }
    }
}

final class DMDelegate: NSObject, URLSessionDownloadDelegate {

    private let fileProvider = FileProvider()
    
    var actor: DMActor?
    var items: [DownloadItemModel] = []

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        guard totalBytesExpectedToWrite > 0 else { return }

        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)

        Task {
            await actor?.updateProgress(taskId: downloadTask.taskIdentifier,
                                       progress: progress)
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {

        guard let item = items.first(where: { $0.taskId == downloadTask.taskIdentifier }) else { return }
        
        _ = try? fileProvider.moveFileToDocuments(from: location, fileName: item.fileName)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {

        guard (error as? URLError)?.code != .cancelled else { return }
        
        Task {
            await actor?.complete(taskId: task.taskIdentifier,
                                  error: error,
                                  session: session)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
        Task { @MainActor in
            NotificationService.shared.showDownloadFinished()
            
            (UIApplication.shared.delegate as? AppDelegate)?.backgroundCompletionHandler?()
        }
    }
}
