import Foundation
import CoreData

@objc(SaveState)
public class SaveState: NSManagedObject {
    override public func prepareForDeletion() {
        super.prepareForDeletion()
        let persistence = PersistenceCoordinator.shared
        let filePath = self.path(in: persistence)
        do {
            try persistence.deleteFile(path: filePath)
        } catch {
            print("[warning] save state deletion failed: \(error.localizedDescription)")
        }
    }
    
    func path(in persistence: PersistenceCoordinator) -> URL {
        return persistence.getPath(name: self.id.uuidString, fileExtension: self.fileExtension, base: persistence.saveStateDirectory)
    }
}
