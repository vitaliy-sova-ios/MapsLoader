//
//  DMActorStorage.swift
//  TestMapLoader
//
//  Created by Vitaliy on 15.05.2026.
//

import Foundation

struct DMActorStorage {
    
    nonisolated private static let key = "download.items"
    
    nonisolated static func saveAllItems(_ items: [DownloadItemModel]) {
        let data = try? JSONEncoder().encode(items)
        UserDefaults.standard.set(data, forKey: key)
    }

    nonisolated static func getSavedItems() -> [DownloadItemModel] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([DownloadItemModel].self, from: data)) ?? []
    }
    
    nonisolated static func getItemName(by taskId: Int) -> String? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        guard let savedItems = try? JSONDecoder().decode([DownloadItemModel].self, from: data) else {
            return nil
        }
        return savedItems.first(where: { $0.taskId == taskId })?.fileName
    }
}
