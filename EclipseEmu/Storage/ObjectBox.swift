import CoreData

/// A type-safe way of passing objects between isolation barriers.
struct ObjectBox<T: NSManagedObject>: Equatable, Hashable, Sendable {
    let id: NSManagedObjectID

    init(_ object: T) {
        self.id = object.objectID
    }

    init(unsafeID: NSManagedObjectID) {
        self.id = unsafeID
    }

    func get(in context: NSManagedObjectContext) throws(PersistenceError) -> T {
        do {
            guard let object = try context.existingObject(with: self.id) as? T else {
                unreachable("object is not castable to \(String(describing: T.self)). this is a fatal error")
            }
            return object
        } catch {
            throw .obtain(error)
        }
    }

    func tryGet(in context: NSManagedObjectContext) -> T? {
        try? context.existingObject(with: self.id) as? T
    }
}


