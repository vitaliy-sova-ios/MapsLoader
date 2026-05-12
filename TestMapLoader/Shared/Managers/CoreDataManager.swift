import Foundation
import CoreData

final class CoreDataManager {

    // MARK: - Singleton

    static let shared = CoreDataManager()

    // MARK: - Properties

    private let persistentContainer: NSPersistentContainer

    private let backgroundContext: NSManagedObjectContext

    // MARK: - Init

    private init() {

        persistentContainer = NSPersistentContainer(name: "CoreData")

        persistentContainer.loadPersistentStores { _, error in

            if let error {
                fatalError("CoreData error: \(error)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

        backgroundContext = persistentContainer.newBackgroundContext()

        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save One

    func saveTask(fileName: String,
                  url: String,
                  status: String,
                  taskId: Int64) {

        let context = backgroundContext

        context.perform {

            let request: NSFetchRequest<DownloadTaskEntity> =
                DownloadTaskEntity.fetchRequest()

            request.predicate =
                NSPredicate(format: "fileName == %@", fileName)

            let entity = (try? context.fetch(request).first)
                ?? DownloadTaskEntity(context: context)

            entity.fileName = fileName
            entity.url = url
            entity.status = status
            entity.taskId = taskId

            guard context.hasChanges else { return }

            try? context.save()
        }
    }
    
    func saveTask(_ task: DownloadItemModel) {
        saveTask(fileName: task.fileName, url: task.url, status: task.status.rawValue, taskId: Int64(task.taskId ?? 0))
    }

    // MARK: - Save Many

    func saveTasks(_ tasks: [DownloadItemModel]) {

        let context = backgroundContext

        context.perform {

            for task in tasks {

                let request: NSFetchRequest<DownloadTaskEntity> = DownloadTaskEntity.fetchRequest()

                request.predicate = NSPredicate(format: "fileName == %@", task.fileName)

                let entity = (try? context.fetch(request).first) ?? DownloadTaskEntity(context: context)

                entity.fileName = task.fileName
                entity.url = task.url
                entity.status = task.status.rawValue
                entity.taskId = Int64(task.taskId ?? 0)
            }

            guard context.hasChanges else { return }

            try? context.save()
        }
    }

    // MARK: - Remove

    func removeTask(byName name: String) {

        let context = backgroundContext

        context.perform {

            let request: NSFetchRequest<DownloadTaskEntity> = DownloadTaskEntity.fetchRequest()

            request.predicate = NSPredicate(format: "fileName == %@", name)

            guard let entity = try? context.fetch(request).first else {
                return
            }

            context.delete(entity)

            guard context.hasChanges else { return }

            try? context.save()
        }
    }

    // MARK: - Fetch

    func fetchAll() -> [DownloadItemModel] {

        let context = backgroundContext
        
        let request: NSFetchRequest<DownloadTaskEntity> = DownloadTaskEntity.fetchRequest()
        
        let result = (try? context.fetch(request)) ?? []
        
        return result.map {
            
            DownloadItemModel(
                fileName: $0.fileName ?? "",
                url: $0.url ?? "",
                status: DownloadItemStatus(rawValue: $0.status ?? "") ?? .pending,
                progress: 0,
                taskId: Int($0.taskId)
            )
        }
    }
}
