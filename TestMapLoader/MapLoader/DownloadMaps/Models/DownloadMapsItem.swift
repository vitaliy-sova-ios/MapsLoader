//
//  DownloadMapsItem.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import Foundation

struct DownloadMapsItem {
    let title: String
    let fileName: String?
    let isMap: Bool
    
    var children: [DownloadMapsItem] = []
}
