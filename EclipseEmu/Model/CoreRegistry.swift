import Foundation
import EclipseKit

final class CoreRegistry: ObservableObject {
    private let settings: Settings
    private let cores: [Box<GameCoreInfo>]
    private let coresByID: [String: Box<GameCoreInfo>]
    private let coresBySystem: [GameSystem: [Box<GameCoreInfo>]]

    init(cores: [Box<GameCoreInfo>], settings: Settings) {
        self.cores = cores
        self.settings = settings

        self.coresByID = cores.reduce(into: [:]) { dict, core in
            let string = String(cString: core.value.id)
            dict[string] = core
        }

        self.coresBySystem = cores.reduce(into: [:]) { dict, core in
            let systems = UnsafeBufferPointer(start: core.value.supportedSystems, count: Int(core.value.supportedSystemsCount))
            for system in systems {
                dict[system, default: [Box<GameCoreInfo>]()].append(core)
            }
        }
    }

    @inlinable
    func get(for game: Game) -> GameCoreInfo? {
        self.get(for: game.system)
    }

    func get(for system: GameSystem) -> GameCoreInfo? {
        let registered: Box<GameCoreInfo>? = if let coreID = settings.registeredCores[system] {
            self.coresByID[coreID]
        } else {
            nil
        }

        let box = registered ?? self.coresBySystem[system]?.first
        return box?.value
    }
}
