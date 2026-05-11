//
//  FileURLBuilder.swift
//  TestMapLoader
//
//  Created by Vitaliy on 10.05.2026.
//

import Foundation

struct FileURLBuilder {
    static func mapsUrl(for fileName: String) -> String {
        "https://download.osmand.net/download?standard=yes&file=\(fileName)"
    }
}
