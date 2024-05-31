import CoreData
import Foundation

public extension SaveState {
    @nonobjc class func fetchRequest() -> NSFetchRequest<SaveState> {
        return NSFetchRequest<SaveState>(entityName: "SaveState")
    }

    @NSManaged var id: UUID
    @NSManaged var name: String?
    @NSManaged var isAuto: Bool
    @NSManaged var date: Date?
    @NSManaged var fileExtension: String?

    @NSManaged var game: Game?
    @NSManaged var preview: ImageAsset?
}

extension SaveState: Identifiable {}
