//
//  DMProgressPublisher.swift
//  TestMapLoader
//
//  Created by Vitaliy on 12.05.2026.
//

actor DMProgressPublisher {

    // MARK: - Stream bridge

    private var continuation: AsyncStream<DownloadItemProgressModel>.Continuation?

    let progressStream: AsyncStream<DownloadItemProgressModel>

    init() {

        var continuationRef: AsyncStream<DownloadItemProgressModel>.Continuation?

        self.progressStream = AsyncStream { continuation in
            continuationRef = continuation
        }

        self.continuation = continuationRef
    }

    // MARK: - Public API

    func emitProgress(_ model: DownloadItemProgressModel) {
        continuation?.yield(model)
    }

    func finishStream() {
        continuation?.finish()
    }
}
