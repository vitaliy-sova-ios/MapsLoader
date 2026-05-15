//
//  DMModels.swift
//  TestMapLoader
//
//  Created by Vitaliy on 12.05.2026.
//

import Foundation

// MARK: - Models

enum DownloadItemStatus: String, Codable {
    case pending
    case downloading
    case finished
    case cancelled
}

struct DownloadItemModel: Codable {
    let fileName: String
    let url: String
    var status: DownloadItemStatus
    var progress: Float
    var taskId: Int?
    
    var progressModel: DownloadItemProgressModel {
        DownloadItemProgressModel(fileName: fileName, status: status, progress: progress)
    }
}

struct DownloadItemProgressModel {
    let fileName: String
    let status: DownloadItemStatus
    let progress: Float
}
