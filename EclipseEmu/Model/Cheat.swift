import Foundation
import CoreData

@objc(Cheat)
public class Cheat: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Cheat> {
        return NSFetchRequest<Cheat>(entityName: "Cheat")
    }

    @NSManaged public var code: String?
    @NSManaged public var enabled: Bool
    @NSManaged public var label: String?
    @NSManaged public var priority: Int16
    @NSManaged public var type: String?
    @NSManaged public var game: Game?
}
