//
//  DMProgressPublisher.swift
//  TestMapLoader
//
//  Created by Vitaliy on 12.05.2026.
//

import Foundation

actor DMProgressPublisher {
    
    // MARK: - Stream bridge
    
    private var continuations: [UUID: AsyncStream<DownloadItemProgressModel>.Continuation] = [:]
    
    func stream() -> AsyncStream<DownloadItemProgressModel> {
        
        let id = UUID()
        
        return AsyncStream { continuation in
            
            continuations[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.removeContinuation(id)
                }
            }
        }
    }
    
    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
    
    func emitProgress(_ model: DownloadItemProgressModel) {
        for continuation in continuations.values {
            continuation.yield(model)
        }
    }
}
