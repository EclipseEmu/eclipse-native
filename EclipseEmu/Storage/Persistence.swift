import CoreData
import EclipseKit
import SwiftUI

struct Persistence: Sendable {
    static let preview: Persistence = Persistence(inMemory: true)

    struct Object<T: NSManagedObject>: Sendable, Hashable, Equatable {
        private let id: NSManagedObjectID

        init(id: NSManagedObjectID) {
            self.id = id
        }

        init(object: T) {
            id = object.objectID
        }

        @inlinable
        func get(in context: NSManagedObjectContext) -> T? {
            return context.object(with: id) as? T
        }

        @inlinable
        func unwrap(in context: NSManagedObjectContext) throws -> T {
            guard let object = get(in: context) else {
                throw PersistenceError.unwrapFailed
            }
            return object
        }
    }

    private let container: NSPersistentContainer
    @MainActor @inlinable var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool) {
        container = NSPersistentContainer(name: "EclipseEmu")
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
    }

    @inlinable
    func perform<T: Sendable>(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async rethrows -> T {
        try await self.container.performBackgroundTask(block)
    }

    func save(in context: NSManagedObjectContext) throws(PersistenceError) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }

    /// Updates the given object and saves the context
    /// - Parameters:
    ///   - item: The object to update
    ///   - block: The code block to handle the updates of the properties.
    @inlinable
    func update<T: NSManagedObject>(
        _ object: Object<T>,
        _ block: @escaping @Sendable (T, NSManagedObjectContext) throws -> Void
    ) async throws {
        try await self.perform { context in
            let object = try object.unwrap(in: context)
            try block(object, context)
            try context.save()
        }
    }

    /// Updates the given object and saves the context
    /// - Parameters:
    ///   - item: The object to update
    ///   - context: The NSManagedObjectContext you wish to perform the update on
    ///   - block: The code block to handle the updates of the properties.
    @inlinable
    func update<T: NSManagedObject>(
        _ object: Object<T>,
        in context: NSManagedObjectContext,
        _ block: @escaping @Sendable (T, NSManagedObjectContext) -> Void
    ) async throws {
        try await context.perform {
            let object = try object.unwrap(in: context)
            block(object, context)
            try context.save()
        }
    }

    @inlinable
    func delete<T: NSManagedObject>(_ item: Object<T>) async throws {
        try await self.perform { context in
            let object = try item.unwrap(in: context)
            context.delete(object)
            try context.save()
        }
    }

    @inlinable
    func delete<T: NSManagedObject>(_ item: T, in context: NSManagedObjectContext) {
        context.delete(item)
    }

    @inlinable
    func delete<T: NSManagedObject>(_ id: Object<T>, in context: NSManagedObjectContext) throws {
        let item = try id.unwrap(in: context)
        delete(item, in: context)
    }

    @inlinable
    func delete(_ id: NSManagedObjectID, in context: NSManagedObjectContext) throws {
        try delete(.init(id: id), in: context)
    }

    @inlinable
    func bulkDelete<T: NSManagedObject>(request: NSFetchRequest<T>) async throws {
        try await container.performBackgroundTask { context in
            let request = T.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeObjectIDs

            guard
                let batchDelete = try context.execute(deleteRequest) as? NSBatchDeleteResult,
                let deleteResult = batchDelete.result as? [NSManagedObjectID]
            else { return }

            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: deleteResult],
                into: [context]
            )
        }
    }
}

private struct PersistenceKey: EnvironmentKey {
    static let defaultValue = Persistence.preview
}

extension EnvironmentValues {
    var persistence: Persistence {
        get { self[PersistenceKey.self] }
        set { self[PersistenceKey.self] = newValue }
    }
}
