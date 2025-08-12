import GameController
import EclipseKit
import Foundation
import CoreData

@MainActor
struct ControlBindingsManager: ~Copyable {
    private let persistence: Persistence
	private let game: ObjectBox<GameObject>?
	private let system: System
    private let settings: Settings
    
	static let encoder: JSONEncoder = .init()
	static let decoder: JSONDecoder = .init()

    init(persistence: Persistence, settings: Settings, game: ObjectBox<GameObject>?, system: System) {
        self.persistence = persistence
		self.game = game
		self.system = system
        self.settings = settings
    }

    borrowing func load<S: InputSourceDescriptorProtocol>(for source: S) -> S.Bindings {
        let config: S.Object? = if
            let game = game?.tryGet(in: persistence.mainContext),
            let config = source.obtain(for: game)
        {
            config
        } else {
            source.obtain(for: system, persistence: persistence, settings: settings)
        }
        
        if let config, let bindings = try? S.decode(config, decoder: Self.decoder) {
            return bindings
        }
        
		return S.defaults(for: system)
	}
}
