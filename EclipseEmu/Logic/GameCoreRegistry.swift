import Foundation
import EclipseKit

class GameCoreRegistry {
    static let shared = GameCoreRegistry()
    private var registered = [GameSystem:GameCore]()
    var allCores = [GameCore]()
    
    func get(for system: GameSystem) -> GameCore? {
        self.registered[system]
    }
    
    func register<T: GameCore>(core: T, for system: GameSystem) -> Void {
        self.registered[system] = core
        if !self.allCores.contains(where: { type(of: $0).id == T.id }) {
            self.allCores.append(core)
        }
    }
}
