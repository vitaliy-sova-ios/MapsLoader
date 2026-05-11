//
//  DownloadMapsTableHeader.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import UIKit

class DownloadMapsTableHeader: UIView {

    let storageView = StorageView(frame: .infinite)
    
    let contentOffset = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
    
    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear

        storageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(storageView)
        
        NSLayoutConstraint.activate([
            storageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentOffset.left),
            storageView.topAnchor.constraint(equalTo: topAnchor, constant: contentOffset.top),
            storageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentOffset.right),
            storageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
