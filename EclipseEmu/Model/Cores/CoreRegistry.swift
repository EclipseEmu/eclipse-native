import Foundation
import SwiftUI
import EclipseKit

@MainActor
final class CoreRegistry: ObservableObject {
	private static let decoder: JSONDecoder = JSONDecoder()
	private static let encoder: JSONEncoder = JSONEncoder()

	@AppStorage(Settings.Keys.registeredCores.rawValue, store: Settings.defaults)
	private var rawRegisteredCores: Data?

	private func getRegisteredCores() -> [System : Core] {
		guard
			let rawRegisteredCores,
			let cores = try? Self.decoder.decode([System : Core].self, from: rawRegisteredCores)
		else {
			return [:]
		}
		return cores
	}

	func cores(for system: System) -> [Core] {
		Core.allCases.filter { core in
			core.type.systems.contains(system)
		}
	}

	func get(for game: GameObject) -> Core? {
		self.get(for: game.system)
	}

	func get(for system: System) -> Core? {
		let registeredCores = getRegisteredCores()
		if let core = registeredCores[system] {
			return core
		}

		return Core.allCases.first { core in
			core.type.systems.contains(system)
		}
	}

	func set(_ core: Core?, for system: System) {
		var registered = getRegisteredCores()
		if let core {
			registered[system] = core
		} else {
			registered.removeValue(forKey: system)
		}
		rawRegisteredCores = try? Self.encoder.encode(registered)
	}

	func cheatFormats(for game: GameObject) -> [CoreCheatFormat] {
		get(for: game)?.type.cheatFormats(for: game.system) ?? []
	}

	func features(for game: GameObject) -> CoreFeatures {
		get(for: game)?.type.features(for: game.system) ?? []
	}
}
