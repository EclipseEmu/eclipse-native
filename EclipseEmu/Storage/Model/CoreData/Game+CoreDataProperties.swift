import CoreData
import EclipseKit
import Foundation

public extension Game {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game")
    }

    @NSManaged var dateAdded: Date?
    @NSManaged var datePlayed: Date?
    @NSManaged var id: UUID
    @NSManaged var md5: String!
    @NSManaged var name: String?
    @NSManaged var romExtension: String?
    @NSManaged var saveExtension: String?
    @NSManaged var system: GameSystem

    @NSManaged var boxart: ImageAsset?
    @NSManaged var saveStates: NSSet?
    @NSManaged var cheats: NSSet?
    @NSManaged var collections: NSSet?
}

extension Game: Identifiable {}
