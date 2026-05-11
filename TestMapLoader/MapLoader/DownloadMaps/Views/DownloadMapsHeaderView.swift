//
//  DownloadMapsHeaderView.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import UIKit

class DownloadMapsHeaderView: UIView {

    private let titleLabel: UILabel = {

        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .init(hexString: "#3C3C43").withAlphaComponent(0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label

    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {

        backgroundColor = .clear
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            // Title
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 16)
        ])

    }

    // MARK: - Public

    func configure(text: String) {
        titleLabel.text = text
    }
}
