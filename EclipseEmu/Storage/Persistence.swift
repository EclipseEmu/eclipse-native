import CoreData
import Foundation
import OSLog

final class Persistence: Sendable, ObservableObject {
    @MainActor
    static let shared = Persistence(inMemory: false)

    private let container: NSPersistentContainer
    @MainActor let mainContext: NSManagedObjectContext

    let objects: ObjectActor
    let files: FileSystem

    @inlinable
    func objectID(from uriRepresentation: URL) -> NSManagedObjectID? {
        self.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uriRepresentation)
    }

    @MainActor
    init(inMemory: Bool) {
        files = .shared
        container = NSPersistentContainer(name: "EclipseEmu")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
//        else {
//            var storeFile = FileManager
//                .default
//                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
//                .first!
//                .appendingPathComponent("Local.sqlite")
//
//            let localDescription = NSPersistentStoreDescription(url: storeFile)
//            localDescription.configuration = "Local"
//            localDescription.shouldMigrateStoreAutomatically = true
//            localDescription.shouldInferMappingModelAutomatically = true
//
//            container.persistentStoreDescriptions = [localDescription]
//        }

        container.loadPersistentStores { description, error in
            guard let error else { return }
            fatalError("Failed to load persistent stores: \(error.localizedDescription)")
        }

        mainContext = container.viewContext
        mainContext.automaticallyMergesChangesFromParent = true
        mainContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

        let objectsContext = container.newBackgroundContext()
        objectsContext.automaticallyMergesChangesFromParent = true
        objectsContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        objects = ObjectActor(objectContext: objectsContext, fileSystem: files)
    }
}
