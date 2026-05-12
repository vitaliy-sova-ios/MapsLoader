//
//  Array.swift
//  facettes
//
//  Created by Vitaliy on 22.07.2024.
//

import Foundation

extension Array {
    func safeIndex(_ index: Int) -> Element? {
        if self.indices.contains(index) {
            return self[index]
        }
                
        return nil
    }
}
