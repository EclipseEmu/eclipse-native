import CoreData
import Foundation
import OSLog

final class Persistence: Sendable, ObservableObject {
    @MainActor
    static let shared = Persistence(inMemory: true)

    private let container: NSPersistentContainer
    @MainActor let mainContext: NSManagedObjectContext

    let objects: ObjectActor
    let files: FileSystem

    @MainActor
    private static let managedObjectModel: NSManagedObjectModel = {
        let bundle = Bundle(for: Persistence.self)
        guard let url = bundle.url(forResource: "EclipseEmu", withExtension: "momd") else {
            fatalError("Failed to locate model file for xcdatamodeld")
        }
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("Failed to load model file for xcdatamodeld")
        }
        return model
    }()


    @inlinable
    func objectID(from uriRepresentation: URL) -> NSManagedObjectID? {
        self.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uriRepresentation)
    }

    @MainActor
    init(inMemory: Bool) {
        Logger.coredata.info("setting up persistence instance")
        files = .shared
        container = NSPersistentContainer(name: "EclipseEmu", managedObjectModel: Self.managedObjectModel)

        if inMemory {
            let persistentStoreDescription = NSPersistentStoreDescription()
            persistentStoreDescription.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [persistentStoreDescription]
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
