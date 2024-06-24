import CoreData
import EclipseKit
import Foundation

@objc(Game)
public final class Game: NSManagedObject, Identifiable {
    @nonobjc static func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game")
    }

    @NSManaged public var id: UUID!
    @NSManaged public var md5: String!

    @NSManaged public var name: String?
    @NSManaged public var rawSystem: Int32
    @NSManaged public var romExtension: String?
    @NSManaged public var saveExtension: String?

    @NSManaged public var dateAdded: Date!
    @NSManaged public var datePlayed: Date?

    @NSManaged public var boxart: ImageAsset?
    @NSManaged public var cheats: NSSet?
    @NSManaged public var collections: NSSet?
    @NSManaged public var saveStates: NSSet?

    // MARK: Accessors for cheats

    @objc(addCheatsObject:)
    @NSManaged public func addToCheats(_ value: Cheat)

    @objc(removeCheatsObject:)
    @NSManaged public func removeFromCheats(_ value: Cheat)

    @objc(addCheats:)
    @NSManaged public func addToCheats(_ values: NSSet)

    @objc(removeCheats:)
    @NSManaged public func removeFromCheats(_ values: NSSet)

    // MARK: Accessors for collections

    @objc(addCollectionsObject:)
    @NSManaged public func addToCollections(_ value: GameCollection)

    @objc(removeCollectionsObject:)
    @NSManaged public func removeFromCollections(_ value: GameCollection)

    @objc(addCollections:)
    @NSManaged public func addToCollections(_ values: NSSet)

    @objc(removeCollections:)
    @NSManaged public func removeFromCollections(_ values: NSSet)

    // MARK: Accessors for save states

    @objc(addSaveStatesObject:)
    @NSManaged public func addToSaveStates(_ value: SaveState)

    @objc(removeSaveStatesObject:)
    @NSManaged public func removeFromSaveStates(_ value: SaveState)

    @objc(addSaveStates:)
    @NSManaged public func addToSaveStates(_ values: NSSet)

    @objc(removeSaveStates:)
    @NSManaged public func removeFromSaveStates(_ values: NSSet)

    // MARK: Additional Getters/Setters

    var romPath: Files.Path? {
        if let md5 {
            .rom(md5, romExtension)
        } else {
            nil
        }
    }

    var savePath: Files.Path {
        .save(id, saveExtension)
    }

    var system: GameSystem {
        get {
            GameSystem(rawValue: UInt32(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int32(truncatingIfNeeded: newValue.rawValue)
        }
    }

    // MARK: Method overrides

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date.now, forKey: #keyPath(Game.dateAdded))
    }

    override public func willSave() {
        super.willSave()

        if isDeleted {
            do {
                try Files.shared.deleteSync(file: savePath)

                // Delete the ROM only if this game is the only one left
                if let romPath, let managedObjectContext {
                    let request = Game.fetchRequest()
                    request.predicate = NSPredicate(format: "md5 == %@", md5)
                    request.includesPropertyValues = false
                    request.includesSubentities = false
                    let count = try managedObjectContext.count(for: request)

                    guard count <= 1 && count > -1 else { return }

                    try Files.shared.deleteSync(file: romPath)
                }
            } catch {
                print("[warning] failed to delete rom: \(error.localizedDescription)")
            }
        }
    }

    static func countGamesWithHash(md5: String, in context: NSManagedObjectContext) throws -> Int {
        let request = Game.fetchRequest()
        request.predicate = NSPredicate(format: "md5 == %@", md5)
        request.includesPropertyValues = false
        request.includesSubentities = false
        return try context.count(for: request)
    }
}
