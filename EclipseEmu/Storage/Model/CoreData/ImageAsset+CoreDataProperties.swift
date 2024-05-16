import CoreData

extension ImageAsset {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageAsset> {
        return NSFetchRequest<ImageAsset>(entityName: "ImageAsset")
    }

    @NSManaged public var id: UUID
    @NSManaged public var fileExtension: String?

    @NSManaged public var game: Game?
    @NSManaged public var saveState: ImageAsset?
}

extension ImageAsset: Identifiable {}
