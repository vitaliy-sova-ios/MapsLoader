//
//  CoreDataManager.swift
//  TestMapLoader
//
//  Created by Vitaliy on 10.05.2026.
//

import Foundation
import CoreData

final class CoreDataManager {

    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    private init() {

        persistentContainer = NSPersistentContainer(name: "CoreData")

        persistentContainer.loadPersistentStores { _, error in
            if let error {
                print("Core Data error:", error)
            }
        }
    }

    // MARK: - Context shortcut
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveTask(fileName: String, url: String, status: String, taskId: Int64) {

        context.perform {

            let request: NSFetchRequest<DownloadTaskEntity> = DownloadTaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "fileName == %@", fileName)

            let entity = (try? self.context.fetch(request).first)
                            ?? DownloadTaskEntity(context: self.context)

            entity.fileName = fileName
            entity.url = url
            entity.status = status
            entity.taskId = taskId

            try? self.context.save()
        }
    }

    func removeTask(byName name: String) {
        
        context.perform {
            
            let request: NSFetchRequest<DownloadTaskEntity> = DownloadTaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "fileName == %@", name)
            
            if let entity = try? self.context.fetch(request).first {
                self.context.delete(entity)
                try? self.context.save()
            }
        }
    }
    
    func fetchAll() -> [DownloadTaskEntity] {
        let request: NSFetchRequest<DownloadTaskEntity> = DownloadTaskEntity.fetchRequest()
        
        return (try? context.fetch(request)) ?? []
    }
}
