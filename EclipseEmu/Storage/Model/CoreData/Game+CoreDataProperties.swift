import Foundation
import CoreData
import EclipseKit

extension Game {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game")
    }

    @NSManaged public var dateAdded: Date?
    @NSManaged public var datePlayed: Date?
    @NSManaged public var id: UUID
    @NSManaged public var md5: String!
    @NSManaged public var name: String?
    @NSManaged public var romExtension: String?
    @NSManaged public var saveExtension: String?
    @NSManaged public var system: GameSystem
    
    @NSManaged public var boxart: ImageAsset?
    @NSManaged public var saveStates: NSSet?
    @NSManaged public var cheats: NSSet?
    @NSManaged public var collections: NSSet?
}

extension Game : Identifiable {}
