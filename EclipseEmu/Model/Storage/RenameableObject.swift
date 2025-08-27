import CoreData

protocol RenameableObject: NSManagedObject {
    var name: String? { get set }
    
    func rename(to newName: String) -> Void
}

// MARK: Conformances

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

extension TouchProfileObject: RenameableObject {
    func rename(to newName: String) {
        self.name = newName
    }
}

extension KeyboardProfileObject: RenameableObject {
    func rename(to newName: String) {
        self.name = newName
    }
}

extension ControllerProfileObject: RenameableObject {
    func rename(to newName: String) {
        self.name = newName
    }
}
