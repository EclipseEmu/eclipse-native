import Foundation
import CoreData

extension SaveState {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SaveState> {
        return NSFetchRequest<SaveState>(entityName: "SaveState")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var isAuto: Bool
    @NSManaged public var date: Date?
    @NSManaged public var fileExtension: String?

    @NSManaged public var game: Game?
    @NSManaged public var preview: ImageAsset?
}

extension SaveState: Identifiable {}
