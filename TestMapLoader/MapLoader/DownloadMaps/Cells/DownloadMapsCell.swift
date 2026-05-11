//
//  DownloadMapsCell.swift
//  TestMapLoader
//
//  Created by Vitaliy on 09.05.2026.
//

import UIKit

enum DownloadMapsCellStatus {
    case idle
    case loading(progress: Float)
    case ready
}

class DownloadMapsCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var icon: UIImageView!
    
    private var item: DownloadMapsItem?
    private var status: DownloadMapsCellStatus = .idle
    
    var onLoadAction: ((DownloadMapsItem) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        progressView.progress = 0
    }
    
    func configure(_ item: DownloadMapsItem, status: DownloadMapsCellStatus) {
        self.item = item
        
        titleLabel.text = item.title
        
        updateStatus(status, animated: false)
    }
    
    func updateStatus(_ status: DownloadMapsCellStatus, animated: Bool = true) {
        guard let item else { return }
        
        switch (self.status, status) {
        case (.loading, .loading(let progress)):
            progressView.setProgress(progress, animated: animated)
            return
        default:
            break
        }
        
        self.status = status
        
        if item.children.isEmpty {

            switch status {
            case .idle:
                accessoryType = .none
                tintColor = .init(hexString: "#CBC7D1")
                icon.tintColor = .init(hexString: "#BEB9C5")
                button.isHidden = false
                progressView.isHidden = true
                progressView.progress = 0
                button.setImage(.icCustomDownload, for: .normal)
                
            case .loading(progress: let progress):
                accessoryType = .none
                tintColor = .init(hexString: "#CBC7D1")
                icon.tintColor = .init(hexString: "#BEB9C5")
                button.isHidden = false
                progressView.isHidden = false
                progressView.setProgress(progress, animated: animated)
                button.setImage(.icCustomDownloadStop, for: .normal)
                
            case .ready:
                accessoryType = .checkmark
                tintColor = .init(hexString: "#14CC9E")
                icon.tintColor = .init(hexString: "#14CC9E")
                button.isHidden = true
                progressView.isHidden = true
            }
            
        } else {
            accessoryType = .disclosureIndicator
            tintColor = .init(hexString: "#CBC7D1")
            icon.tintColor = .init(hexString: "#BEB9C5")
            button.isHidden = true
            progressView.isHidden = true
        }
    }
    
    @IBAction private func buttonAction(_ sender: Any) {
        guard let item else { return }
        
        onLoadAction?(item)
    }
}
