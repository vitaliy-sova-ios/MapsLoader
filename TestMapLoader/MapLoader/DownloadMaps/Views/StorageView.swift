//
//  StorageView.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import UIKit

final class StorageView: UIView {

    // MARK: - UI

    private let containerView: UIView = {

        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 24
        view.translatesAutoresizingMaskIntoConstraints = false
        return view

    }()

    private let titleLabel: UILabel = {

        let label = UILabel()
        label.text = "Device memory"
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.lineBreakMode = .byTruncatingTail
        return label

    }()

    private let valueLabel: UILabel = {

        let label = UILabel()
        label.text = "Free 3.61 Gb"
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .init(hexString: "#7D738C")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label

    }()

    private let progressBackgroundView: UIView = {

        let view = UIView()
        view.backgroundColor = .init(hexString: "#EAE9ED")
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view

    }()

    private let progressFillView: UIView = {

        let view = UIView()
        view.backgroundColor = .init(hexString: "#FF8800")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view

    }()

    private var progressWidthConstraint: NSLayoutConstraint?
    
    private struct Constants {
        static let contentOffset: CGFloat = 20
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {

        backgroundColor = .clear
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        containerView.addSubview(progressBackgroundView)
        progressBackgroundView.addSubview(progressFillView)

        progressWidthConstraint = progressFillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([

            // Container

            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Title

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.contentOffset),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.contentOffset),

            // Value

            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.contentOffset),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: Constants.contentOffset),

            // Progress Background

            progressBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.contentOffset),
            progressBackgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.contentOffset),
            progressBackgroundView.heightAnchor.constraint(equalToConstant: Constants.contentOffset),
            progressBackgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.contentOffset),
            progressBackgroundView.topAnchor.constraint(greaterThanOrEqualTo: valueLabel.bottomAnchor, constant: 16),

            // Progress Fill

            progressFillView.leadingAnchor.constraint(equalTo: progressBackgroundView.leadingAnchor),
            progressFillView.topAnchor.constraint(equalTo: progressBackgroundView.topAnchor),
            progressFillView.bottomAnchor.constraint(equalTo: progressBackgroundView.bottomAnchor),

            progressWidthConstraint!

        ])

    }

    // MARK: - Public

    func configure(freeSpaceText: String, progress: CGFloat) {

        valueLabel.text = freeSpaceText

        setProgress(progress)
    }

    func setProgress(_ progress: CGFloat) {

        layoutIfNeeded()

        let clamped = max(0, min(progress, 1))

        let width = progressBackgroundView.bounds.width * clamped

        progressWidthConstraint?.constant = width

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
