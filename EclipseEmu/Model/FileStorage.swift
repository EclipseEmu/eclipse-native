import Foundation

struct FileStorage {
    let fileManager: FileManager
    
    struct SaveStateDescriptor {
        var name: String
        var date: Date?
    }
    
    func getSaveUrl(for game: Game) -> URL? {
        return nil
    }
    
    func getSaveStates(for game: Game) -> [SaveStateDescriptor] {
        return []
    }
}
