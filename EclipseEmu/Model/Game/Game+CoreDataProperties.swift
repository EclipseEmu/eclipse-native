import Foundation
import CoreData
import EclipseKit

extension Game {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game")
    }

    @NSManaged public var name: String?
    @NSManaged public var system: GameSystem
    @NSManaged public var md5: String
    @NSManaged public var romPath: URL?
    @NSManaged public var savePath: URL?
    @NSManaged public var coverArtPath: URL?
    @NSManaged public var dateAdded: Date
    @NSManaged public var datePlayed: Date?
}

extension Game : Identifiable {}
