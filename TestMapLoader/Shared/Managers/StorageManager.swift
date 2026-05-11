//
//  StorageManager.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import Foundation

struct StorageInfo {
    let total: Int64
    let free: Int64
    let used: Int64

    var usedPercent: Double {
        guard total > 0 else { return 0 }

        return Double(used) / Double(total)
    }
    
    func formatFreeGB() -> String {

        let gb = Double(free) / 1_073_741_824

        return String(format: "Free %.2f Gb", gb)
    }
}

struct StorageInfoProvider {

    static func getInfo() -> StorageInfo? {

        let url = URL(fileURLWithPath: NSHomeDirectory() as String)

        guard let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey

        ]) else {
            return nil
        }

        guard let total = values.volumeTotalCapacity,
              let free = values.volumeAvailableCapacityForImportantUsage else {

            return nil
        }

        let used = Int64(total) - free

        return StorageInfo(
            total: Int64(total),
            free: free,
            used: used
        )
    }
}
