import Foundation
import CoreData
import SwiftUI

final class PersistenceCoordinator {
    static let shared = PersistenceCoordinator()
//    #if DEBUG
    static let preview = PersistenceCoordinator(inMemory: true)
//    #endif
    let external = ExternalStorage()

    let inMemory: Bool
    lazy var games: GameManager = {
        return GameManager(self)
    }()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EclipseEmu")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            
            let localDescription = NSPersistentStoreDescription(url: storeDirectory.appendingPathComponent("Local.sqlite"))
            localDescription.configuration = "Local"
            localDescription.shouldMigrateStoreAutomatically = true
            localDescription.shouldInferMappingModelAutomatically = true
            
            container.persistentStoreDescriptions = [localDescription]
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // FIXME: handle
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    var context: NSManagedObjectContext { container.viewContext }
    
    init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }
    
    func save() {
        do {
            try context.save()
        } catch {
            print("CoreData save failure: \(error.localizedDescription)")
        }
    }
    
    func saveIfNeeded() {
        guard self.context.hasChanges else { return }
        self.save()
    }
    
    func remove(_ object: NSManagedObject) async {
        await container.performBackgroundTask { context in
            let object = context.object(with: object.objectID)
            context.delete(object)
        }
    }
    
    func clear<T: NSManagedObject>(request: NSFetchRequest<T>, in context: NSManagedObjectContext) throws {
        let batchRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
        try batchRequest.fetchRequest.execute()
    }
}

private struct PersistenceCoordinatorKey: EnvironmentKey {
    #if DEBUG
    static let defaultValue: PersistenceCoordinator = PersistenceCoordinator.preview
    #else
    static let defaultValue: PersistenceCoordinator = PersistenceCoordinator.shared
    #endif
}

extension EnvironmentValues {
    var persistenceCoordinator: PersistenceCoordinator {
        get { self[PersistenceCoordinatorKey.self] }
        set { self[PersistenceCoordinatorKey.self] = newValue }
    }
}
