import Foundation
import EclipseKit

class GameCoreRegistry {
    var allCores = [GameCore]()
    private var systemToCore = [GameSystem:Int]()

    init(cores: [GameCore]) {
        self.allCores = cores
    }
    
    func get(for game: Game) -> GameCore? {
        // NOTE: in the future this should also look at the game's settings to resolve the core to use.
        guard let index = self.systemToCore[game.system] else { return nil }
        return self.allCores[index]
    }
    
    func registerDefaults(id: String, for system: GameSystem) -> Void {
        guard let index = self.allCores.firstIndex(where: { $0.id == id }) else { return }
        self.systemToCore[system] = index
    }
}
