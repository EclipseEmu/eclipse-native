import CoreData

protocol RenameableObject: NSManagedObject {
    func rename(to newName: String) -> Void
}

extension Game: RenameableObject {
    @inlinable
    func rename(to newName: String) {
        self.name = newName
    }
}

extension Tag: RenameableObject {
    @inlinable
    func rename(to newName: String) {
        self.name = newName
    }
}

extension SaveState: RenameableObject {
    @inlinable
    func rename(to newName: String) {
        self.name = newName
    }
}
