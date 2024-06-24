import Foundation
import CoreData

@objc(ImageAsset)
public final class ImageAsset: NSManagedObject, Identifiable {
    @nonobjc public static func fetchRequest() -> NSFetchRequest<ImageAsset> {
        return NSFetchRequest<ImageAsset>(entityName: "ImageAsset")
    }

    @NSManaged public var id: UUID!
    @NSManaged public var fileExtension: String?

    @NSManaged public var game: Game?
    @NSManaged public var saveState: SaveState?

    override public func willSave() {
        super.willSave()

        if isDeleted {
            do {
                guard let path else { throw Files.Failure.invalidPath }
                try Files.shared.deleteSync(file: path)
            } catch {
                print("[warning] image deletion failed: \(error.localizedDescription)")
            }
        }
    }

    var path: Files.Path? {
        .image(id, self.fileExtension)
    }
}
