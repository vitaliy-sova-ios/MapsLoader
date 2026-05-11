//
//  String+Ext.swift
//  TestMapLoader
//
//  Created by Vitaliy on 10.05.2026.
//

extension String {
    var firstUppercased: String {
        prefix(1).uppercased() + dropFirst()
    }
}
