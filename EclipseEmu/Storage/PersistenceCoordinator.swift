import CoreData
import Foundation
import SwiftUI

final class PersistenceCoordinator {
    enum Failure: LocalizedError {
        case missingRomPath
        case missingSavePath
        case failedToCreateFile
    }

    static let preview = PersistenceCoordinator(inMemory: true)

    private let inMemory: Bool

    let fileManager: FileManager
    let romDirectory: URL
    let saveDirectory: URL
    let saveStateDirectory: URL
    let imageDirectory: URL

    @usableFromInline
    var context: NSManagedObjectContext { container.viewContext }

    private(set) lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EclipseEmu")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

            let localDescription = NSPersistentStoreDescription(
                url: storeDirectory.appendingPathComponent("Local.sqlite")
            )
            localDescription.configuration = "Local"
            localDescription.shouldMigrateStoreAutomatically = true
            localDescription.shouldInferMappingModelAutomatically = true

            container.persistentStoreDescriptions = [localDescription]
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                // FIXME: handle this error
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is inaccessible, due to permissions/data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private static func createDirectory(path: String, base: URL, with fileManager: FileManager) -> URL {
        let directory = base.appendingPathComponent(path, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        return directory
    }

    init(fileManager: FileManager = .default, inMemory: Bool = false) {
        self.inMemory = inMemory
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileManager = fileManager
        self.romDirectory = Self.createDirectory(path: "roms", base: documentDirectory, with: fileManager)
        self.saveDirectory = Self.createDirectory(path: "saves", base: documentDirectory, with: fileManager)
        self.saveStateDirectory = Self.createDirectory(path: "save_states", base: documentDirectory, with: fileManager)
        self.imageDirectory = Self.createDirectory(path: "images", base: documentDirectory, with: fileManager)
    }

    // MARK: Core Data helpers

    func save() {
        Task { @MainActor in
            do {
                try context.save()
            } catch {
                print("CoreData save failure: \(error.localizedDescription)")
            }
        }
    }

    func saveIfNeeded() {
        guard context.hasChanges else { return }
        save()
    }

    func remove(_ object: NSManagedObject) async {
        await container.performBackgroundTask { context in
            let object = context.object(with: object.objectID)
            context.delete(object)
        }
    }

    func clear(request: NSFetchRequest<any NSFetchRequestResult>, in context: NSManagedObjectContext) throws {
        let batchRequest = NSBatchDeleteRequest(fetchRequest: request)
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
        guard fileManager.fileExists(atPath: path.path) else { return }
        try fileManager.removeItem(at: path)
    }

    @inlinable
    func fileExists(path: URL) -> Bool {
        fileManager.fileExists(atPath: path.path)
    }
}

// MARK: Make PersistenceCoordinator to be available from SwiftUI's envrionment

private struct PersistenceCoordinatorKey: EnvironmentKey {
    #if DEBUG
    static let defaultValue: PersistenceCoordinator = .preview
    #else
    static let defaultValue: PersistenceCoordinator = .shared
    #endif
}

extension EnvironmentValues {
    var persistenceCoordinator: PersistenceCoordinator {
        get { self[PersistenceCoordinatorKey.self] }
        set { self[PersistenceCoordinatorKey.self] = newValue }
    }
}
