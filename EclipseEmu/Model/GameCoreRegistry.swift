import EclipseKit
import Foundation

final class GameCoreRegistry: @unchecked Sendable {
    var allCores = [GameCoreInfo]()
    private var systemToCore = [GameSystem: Int]()

    init(cores: [GameCoreInfo]) {
        self.allCores = cores
    }

    // FIXME: This returns mGBA for SNES games, presumably others too.
    func get(for game: Game) -> GameCoreInfo? {
        // NOTE: in the future this should also look at the game's settings to resolve the core to use.
        guard let index = self.systemToCore[game.system] else { return nil }
        return self.allCores[index]
    }

    func registerDefaults(id: UnsafePointer<CChar>, for system: GameSystem) {
        guard
            let index = self.allCores.firstIndex(where: { id == $0.id })
        else { return }

        self.systemToCore[system] = index
    }
}

extension Array where Element == CChar {
    func isEqual(to cString: UnsafePointer<CChar>) -> Bool {
        var pointer = cString
        var index = 0
        while index < self.count {
            guard self[index] == pointer.pointee && pointer.pointee != 0 else {
                return false
            }

            index += 1
            pointer += 1
        }

        return index == self.count - 1
    }
}
