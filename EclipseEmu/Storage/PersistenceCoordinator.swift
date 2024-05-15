import Foundation
import CoreData
import SwiftUI

fileprivate func createDirectoryIfNeeded(path: String, base: URL, with fileManager: FileManager) -> URL {
    let directory = base.appendingPathComponent(path, isDirectory: true)
    if !fileManager.fileExists(atPath: directory.path) {
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    return directory
}

final class PersistenceCoordinator {
    enum Failure: LocalizedError {
        case missingRomPath
        case missingSavePath
        case failedToCreateFile
    }
    
    static let shared = PersistenceCoordinator()
//    #if DEBUG
    static let preview = PersistenceCoordinator(inMemory: true)
//    #endif

    private let inMemory: Bool
    
    let fileManager: FileManager
    let romDirectory: URL
    let saveDirectory: URL
    let saveStateDirectory: URL
    let imageDirectory: URL
    
    // Core Data properties
    
    @usableFromInline
    var context: NSManagedObjectContext { self.container.viewContext }
    
    lazy private(set) var container: NSPersistentContainer = {
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
    
    init(fileManager: FileManager = .default, inMemory: Bool = false) {
        self.inMemory = inMemory
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileManager = fileManager
        self.romDirectory = createDirectoryIfNeeded(path: "roms", base: documentDirectory, with: fileManager)
        self.saveDirectory = createDirectoryIfNeeded(path: "saves", base: documentDirectory, with: fileManager)
        self.saveStateDirectory = createDirectoryIfNeeded(path: "save_states", base: documentDirectory, with: fileManager)
        self.imageDirectory = createDirectoryIfNeeded(path: "images", base: documentDirectory, with: fileManager)
    }

    // MARK: Core Data helpers
    
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
    
    // MARK: File Helpers
    
    @inlinable
    func getPath(name: String, fileExtension: String?, base: URL) -> URL {
        var filePath = name
        if let fileExtension {
            filePath += "." + fileExtension
        }
        return base.appendingPathComponent(filePath)
    }
    
    @inlinable
    func writeFile(path: URL, contents: Data) throws {
        guard fileManager.createFile(atPath: path.path, contents: contents, attributes: nil) else {
            throw Failure.failedToCreateFile
        }
    }
    
    @inlinable
    func deleteFile(path: URL) throws {
        guard self.fileManager.fileExists(atPath: path.path) else { return }
        try fileManager.removeItem(at: path)
    }
}

// MARK: Make PersistenceCoordinator to be available from SwiftUI's envrionment

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
