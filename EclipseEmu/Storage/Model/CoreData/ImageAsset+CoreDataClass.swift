import Foundation
import CoreData

@objc(ImageAsset)
public class ImageAsset: NSManagedObject {
    override public func prepareForDeletion() {
        super.prepareForDeletion()
        let persistence = PersistenceCoordinator.preview
        let filePath = self.path(in: persistence)
        do {
            try persistence.deleteFile(path: filePath)
        } catch {
            print("[warning] image deletion failed: \(error.localizedDescription)")
        }
    }
    
    func path(in persistence: PersistenceCoordinator) -> URL {
        return persistence.getPath(name: self.id.uuidString, fileExtension: self.fileExtension, base: persistence.imageDirectory)
    }
}
