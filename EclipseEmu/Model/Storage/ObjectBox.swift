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

// MARK: Codable conformance

enum ObjectBoxCodingError: LocalizedError {
    case temporaryID
    
    case missingPersistenceContainer
    case invalidID
}

extension CodingUserInfoKey {
    static let persistence = CodingUserInfoKey(rawValue: "eclipse.persistence")!
}

extension JSONDecoder {
    func attachPersistence(persistence: Persistence) {
        self.userInfo[.persistence] = persistence
    }
}

extension ObjectBox: Encodable {
    func encode(to encoder: any Encoder) throws {
        guard !self.id.isTemporaryID else { throw ObjectBoxCodingError.temporaryID }
        var container = encoder.singleValueContainer()
        try container.encode(self.id.uriRepresentation())
    }
}

extension ObjectBox: Decodable {
    init(from decoder: any Decoder) throws {
        guard
            let value = decoder.userInfo[.persistence],
            let persistence = value as? Persistence
        else { throw ObjectBoxCodingError.missingPersistenceContainer }
        
        let container = try decoder.singleValueContainer()
        let url = try container.decode(URL.self)
        
        guard let id = persistence.objectID(from: url) else { throw ObjectBoxCodingError.invalidID }
        self.id = id
    }
}
