import Foundation
import EclipseKit

@MainActor
final class CoreRegistry: ObservableObject {
    private let settings: Settings
    let cores: [CoreInfo]
    private let coresByID: [String: CoreInfo]
    private let coresBySystem: [GameSystem: [CoreInfo]]

    init(cores: [GameCoreInfo], settings: Settings) {
        self.cores = cores.map(CoreInfo.init)
        self.settings = settings

        self.coresByID = self.cores.reduce(into: [:]) { dict, core in
            dict[core.id] = core
        }

        self.coresBySystem = self.cores.reduce(into: [:]) { dict, core in
            for system in core.supportedSystems {
                dict[system, default: [CoreInfo]()].append(core)
            }
        }
    }

    func cores(for system: GameSystem) -> [CoreInfo] {
        cores.filter { core in
            return core.supportedSystems.contains(system)
        }
    }

    @inlinable
    func get(id: String) -> CoreInfo? {
        coresByID[id]
    }

    @inlinable
    func get(for game: GameObject) -> CoreInfo? {
        self.get(for: game.system)
    }

    func get(for system: GameSystem) -> CoreInfo? {
        return if let coreID = settings.registeredCores[system], let core = self.coresByID[coreID] {
            core
        } else {
            self.coresBySystem[system]?.first
        }
    }
}
