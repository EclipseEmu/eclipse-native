import CoreData

protocol RenameableObject: NSManagedObject {
    func rename(to newName: String) -> Void
}

extension GameObject: RenameableObject {
    @inlinable
    func rename(to newName: String) {
        self.name = newName
    }
}

extension TagObject: RenameableObject {
    @inlinable
    func rename(to newName: String) {
        self.name = newName
    }
}

extension SaveStateObject: RenameableObject {
    @inlinable
    func rename(to newName: String) {
        self.name = newName
    }
}
