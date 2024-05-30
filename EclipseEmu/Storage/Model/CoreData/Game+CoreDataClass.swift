import Foundation
import CoreData

@objc(Game)
public class Game: NSManagedObject {
    public override func prepareForDeletion() {
        super.prepareForDeletion()
        let persistence = PersistenceCoordinator.preview
        let romPath = self.romPath(in: persistence)
        let savePath = self.savePath(in: persistence)
        
        if let md5 = self.md5 {
            Task.detached(priority: .low) {
                let canDeleteRom = await persistence.context.perform {
                    let request = Game.fetchRequest()
                    request.fetchLimit = 2
                    request.predicate = NSPredicate(format: "md5 == %@", md5)
                    request.includesPropertyValues = false
                    request.includesSubentities = false
                    let count = (try? persistence.context.count(for: request)) ?? 0
                    return count < 2
                }
                
                guard canDeleteRom else { return }
                
                do {
                    try persistence.deleteFile(path: romPath)
                } catch {
                    print("[warning] failed to delete rom: \(error.localizedDescription)")
                }
            }
        }
        
        do {
            try persistence.deleteFile(path: savePath)
        } catch {
            print("[warning] failed to delete save: \(error.localizedDescription)")
        }
    }
    
    func romPath(in persistence: PersistenceCoordinator) -> URL {
        persistence.getPath(name: self.md5, fileExtension: self.romExtension, base: persistence.romDirectory)
    }
    
    func savePath(in persistence: PersistenceCoordinator) -> URL {
        persistence.getPath(name: self.id.uuidString, fileExtension: self.saveExtension, base: persistence.saveDirectory)
    }
}
