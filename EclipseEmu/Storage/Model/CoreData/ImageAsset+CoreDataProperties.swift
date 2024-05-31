import CoreData

public extension ImageAsset {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ImageAsset> {
        return NSFetchRequest<ImageAsset>(entityName: "ImageAsset")
    }

    @NSManaged var id: UUID
    @NSManaged var fileExtension: String?

    @NSManaged var game: Game?
    @NSManaged var saveState: ImageAsset?
}

extension ImageAsset: Identifiable {}
