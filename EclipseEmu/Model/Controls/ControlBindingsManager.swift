import GameController
import EclipseKit
import Foundation
import CoreData

@MainActor
final class ControlBindingsManager {
    private let persistence: Persistence
	private let game: ObjectBox<GameObject>?
	private let system: System

	static let encoder: JSONEncoder = .init()
	static let decoder: JSONDecoder = .init()

	init(persistence: Persistence, game: ObjectBox<GameObject>?, system: System) {
        self.persistence = persistence
		self.game = game
		self.system = system
    }

	func load<S: InputSourceDescriptorProtocol>(for source: S) -> S.Bindings {
		// Get specifically for the game
		if
			let game = game?.tryGet(in: persistence.mainContext),
			let config = source.obtain(from: game, system: system, persistence: persistence),
			let bindings = try? S.decode(config, decoder: Self.decoder)
		{
			return bindings
		}

		// Get generally for the system
		let request = S.Object.fetchRequest()
		request.fetchLimit = 1
		request.includesSubentities = false
		request.predicate = source.predicate(system: system)
		if
			let config = try? persistence.mainContext.fetch(request).first as? S.Object,
			let bindings = try? S.decode(config, decoder: Self.decoder)
		{
			return bindings
		}

		return S.defaults(for: system)
	}
}
