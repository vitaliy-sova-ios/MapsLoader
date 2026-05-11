//
//  RegionsParser.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import Foundation

final class RegionParserModel {

    var name: String = ""
    var translate: String?
    
    var type: String?
    var map: String?
    
    var downloadPrefix: String?
    var downloadSuffix: String?
    var innerDownloadPrefix: String?
    var innerDownloadSuffix: String?
    
    var children: [RegionParserModel] = []

    weak var parent: RegionParserModel?
    
    var isAvailable: Bool {
        if let type {
            return type == "map"
        } else if let map {
            return map == "yes"
        } else {
            return true
        }
    }
    
    var fileName: String {
        
        let prefix: String? = resolvedInnerDownloadPrefix ?? resolvedDownloadPrefix
        
        let suffix: String? = resolvedInnerDownloadSuffix ?? resolvedDownloadSuffix
        
        let file = [prefix, name, suffix, "2.obf.zip"]
                        .compactMap{$0}
                        .joined(separator: "_")
        
        return file.firstUppercased
    }
    
    private var resolvedDownloadPrefix: String? {
        downloadPrefix ?? parent?.resolvedDownloadPrefix
    }
    
    private var resolvedInnerDownloadPrefix: String? {
        innerDownloadPrefix ?? parent?.resolvedInnerDownloadPrefix
    }
    
    private var resolvedDownloadSuffix: String? {
        downloadSuffix ?? parent?.resolvedDownloadSuffix
    }
    
    private var resolvedInnerDownloadSuffix: String? {
        innerDownloadSuffix ?? parent?.resolvedInnerDownloadSuffix
    }
}

final class RegionsParser: NSObject, XMLParserDelegate {

    private var roots: [RegionParserModel] = []
    private var stack: [RegionParserModel] = []

    func parse(data: Data) -> [RegionParserModel] {
        roots = []
        stack = []
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        return roots
    }

    // MARK: - Start element
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        
        guard elementName == "region" else { return }

        let region = RegionParserModel()
        
        region.name = attributeDict["name"] ?? ""
        region.translate = normalizedTitle(from: attributeDict["translate"]) ?? region.name.capitalized
        
        region.type = attributeDict["type"]
        region.map = attributeDict["map"]
        
        if attributeDict["inner_download_prefix"] == "$name" {
            region.innerDownloadPrefix = region.name
        }
        
        region.downloadPrefix = attributeDict["download_prefix"]
        region.downloadSuffix = attributeDict["download_suffix"]
        
        if attributeDict["inner_download_prefix"] == "$name" {
            region.innerDownloadPrefix = region.name
        } else {
            region.innerDownloadPrefix = attributeDict["inner_download_prefix"]
        }
        region.innerDownloadSuffix = attributeDict["inner_download_suffix"]

        if let parent = stack.last {
            parent.children.append(region)
            region.parent = parent

        } else {
            roots.append(region)
        }

        stack.append(region)
    }

    // MARK: - End element
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {

        if elementName == "region" {
            stack.removeLast()
        }
    }
    
    private func normalizedTitle(from value: String?) -> String? {
        
        guard let value else {
            return nil
        }

        if !value.contains(";") && !value.contains("=") {
            return value
        }

        let pairs = value.split(separator: ";")

        for pair in pairs {

            let parts = pair.split(separator: "=", maxSplits: 1)

            guard parts.count == 2 else { continue }

            let key = parts[0]

            let val = parts[1]

            if key == "name:en" {
                return String(val)
            }

            if key == "name" {
                return String(val)
            }
        }
        
        if let first = pairs.first {
            return String(first).trimmingCharacters(in: CharacterSet(charactersIn: "= "))
        }

        return nil
    }
}
