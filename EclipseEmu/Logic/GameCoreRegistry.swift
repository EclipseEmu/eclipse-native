import Foundation
import EclipseKit

class GameCoreRegistry {
    var allCores = [GameCoreInfo]()
    private var systemToCore = [GameSystem:Int]()

    init(cores: [GameCoreInfo]) {
        self.allCores = cores
    }
    
    func get(for game: Game) -> GameCoreInfo? {
        // NOTE: in the future this should also look at the game's settings to resolve the core to use.
        guard let index = self.systemToCore[game.system] else { return nil }
        return self.allCores[index]
    }
    
    func registerDefaults(id: UnsafePointer<CChar>, for system: GameSystem) -> Void {
        guard
            let index = self.allCores.firstIndex(where: { id == $0.id })
        else { return }
        
        self.systemToCore[system] = index
    }
}

extension Array where Element == CChar {
    func isEqual(to cString: UnsafePointer<CChar>) -> Bool {
        var ptr = cString
        var i = 0
        while i < self.count {
            if self[i] != ptr.pointee || ptr.pointee == 0 {
                return false
            }
            
            i += 1
            ptr += 1
        }
        
        return i == self.count - 1
    }
}
