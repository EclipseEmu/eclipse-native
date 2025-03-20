import CoreData
import OSLog
import SwiftUI

extension NSManagedObjectContext {
    func saveIfNeeded() throws(PersistenceError) {
        guard hasChanges else { return }
        do {
            Logger.coredata.info("saving managed object context")
            try save()
        } catch {
            Logger.coredata.error("failed to save managed object context: \(error.localizedDescription)")
            throw .saveError(error)
        }
    }
}

extension FetchedResults where Result: NSManagedObject {
    func boxedItems(for indicies: IndexSet) -> [ObjectBox<Result>] {
        var boxes: [ObjectBox<Result>] = []
        for index in indicies {
            boxes.append(ObjectBox(self[index]))
        }
        return boxes
    }
}

extension Collection where Element: NSManagedObject {
    func boxedItems() -> [ObjectBox<Self.Element>] {
        var boxes: [ObjectBox<Self.Element>] = []
        for item in self {
            boxes.append(ObjectBox(item))
        }
        return boxes
    }
}
