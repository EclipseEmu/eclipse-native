import Foundation
import CoreData

@objc(SaveState)
public final class SaveState: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SaveState> {
        return NSFetchRequest<SaveState>(entityName: "SaveState")
    }

    @NSManaged public var id: UUID!

    @NSManaged public var date: Date?
    @NSManaged public var fileExtension: String?
    @NSManaged public var isAuto: Bool
    @NSManaged public var name: String?
    
    @NSManaged public var game: Game?
    @NSManaged public var preview: ImageAsset?

    override public func willSave() {
        super.willSave()
        guard isDeleted else { return }

        do {
            try Files.shared.deleteSync(file: self.file)
        } catch {
            print("[warning] save state deletion failed: \(error.localizedDescription)")
        }
    }

    var file: Files.Path {
        .saveState(self.id)
    }
}
