import GameController
import EclipseKit
import Foundation
import CoreData

protocol InputSourceDescriptorProtocol: Sendable {
    associatedtype Bindings: Codable & Sendable
	associatedtype Object: ControlsProfileObject

	static func encode(_ bindings: Bindings, encoder: JSONEncoder, into object: Self.Object) throws
	static func decode(_ data: Self.Object, decoder: JSONDecoder) throws -> Self.Bindings

	static func defaults(for system: System) -> Self.Bindings

	func obtain(for game: GameObject) -> Self.Object?
    
    @MainActor
    func obtain(for system: System, persistence: Persistence, settings: Settings) -> Self.Object?
}
