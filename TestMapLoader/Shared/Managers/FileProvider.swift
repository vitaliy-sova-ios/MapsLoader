//
//  FileProvider.swift
//  TestMapLoader
//
//  Created by Vitaliy on 10.05.2026.
//

import Foundation

struct FileProvider {

    private let fileManager = FileManager.default
    
    private var mapsURL: URL

    init() {
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.mapsURL = documentsURL.appendingPathComponent("Maps")
        self.setupDirectory()
    }
    // MARK: - Public

    @discardableResult
    func moveFileToDocuments(from tempURL: URL, fileName: String) throws -> URL {

        let destinationURL = mapsURL
            .appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: tempURL, to: destinationURL)

        return destinationURL
    }

    /// Проверяет, есть ли файл в Documents
    func fileExistsInDocuments(fileName: String) -> Bool {
        return fileManager.fileExists(atPath: mapsURL.appendingPathComponent(fileName).path)
    }

    // MARK: - Private

    private mutating func setupDirectory() {
        if !fileManager.fileExists(atPath: mapsURL.path) {
            do {
                try fileManager.createDirectory(at: mapsURL,
                                                withIntermediateDirectories: true)
            } catch {
                print("Failed to create Maps folder:", error)
            }
        }
        
        do {
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try mapsURL.setResourceValues(values)
            
        } catch {
            print("Failed to exclude folder from iCloud backup:", error)
        }
    }
}
