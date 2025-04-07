import CoreData

/// A type-safe way of passing objects between isolation barriers.
struct ObjectBox<T: NSManagedObject>: Equatable, Hashable, Sendable {
    let id: NSManagedObjectID

    init(id: NSManagedObjectID) {
        self.id = id
    }

    init(_ object: T) {
        self.id = object.objectID
    }

    func get(in context: NSManagedObjectContext) throws(PersistenceError) -> T {
        let object: NSManagedObject
        do {
            object = try context.existingObject(with: self.id)
        } catch {
            throw .obtain(error)
        }
        guard let object = object as? T else {
            throw .typeMismatch
        }
        return object
    }

    func tryGet(in context: NSManagedObjectContext) -> T? {
        try? context.existingObject(with: self.id) as? T
    }
}


