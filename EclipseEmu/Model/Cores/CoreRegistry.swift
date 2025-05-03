import Foundation
import SwiftUI
import EclipseKit

import mGBAEclipseCore

@MainActor
final class CoreRegistry: ObservableObject {
    let cores: [CoreInfo]

    private static let decoder: JSONDecoder = JSONDecoder()
    private static let encoder: JSONEncoder = JSONEncoder()

    @AppStorage(Settings.Keys.registeredCores.rawValue, store: Settings.defaults)
    private var rawRegisteredCores: Data?

    private let coresByID: [String: CoreInfo]
    private let coresBySystem: [GameSystem : [CoreInfo]]

    init(cores: [GameCoreInfo]) {
        self.cores = cores.map(CoreInfo.init)

        self.coresByID = self.cores.reduce(into: [:]) { dict, core in
            dict[core.id] = core
        }

        self.coresBySystem = self.cores.reduce(into: [:]) { dict, core in
            for system in core.supportedSystems {
                dict[system, default: [CoreInfo]()].append(core)
            }
        }
    }

    private func getRegisteredCores() -> [GameSystem : String] {
        guard
            let rawRegisteredCores,
            let cores = try? Self.decoder.decode([GameSystem : String].self, from: rawRegisteredCores)
        else {
            return [.gba : String(cString: mGBACoreInfo.id)]
        }
        return cores
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
        let registeredCores = getRegisteredCores()
        guard let coreID = registeredCores[system] else { return self.coresBySystem[system]?.first }
        guard !coreID.isEmpty else { return nil }
        guard let core = self.coresByID[coreID] else { return self.coresBySystem[system]?.first }
        return core
    }

    func set(_ core: CoreInfo?, for system: GameSystem) {
        var registeredCores = getRegisteredCores()
        registeredCores[system] = core?.id ?? ""
        rawRegisteredCores = try? Self.encoder.encode(registeredCores)
    }
}
