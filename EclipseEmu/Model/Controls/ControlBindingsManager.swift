import GameController
import EclipseKit
import Foundation

struct ControlsConfigData: ~Copyable {
    let version: Int16
    let data: Data
}

protocol InputSourceDescriptorProtocol: Sendable {
    associatedtype Bindings: Codable & Sendable

    var kind: ControlsInputSourceKind { get }
    var id: String? { get }

    func encode(_ bindings: Bindings, encoder: JSONEncoder) throws -> ControlsConfigData
    func decode(_ data: consuming ControlsConfigData, decoder: JSONDecoder) throws -> Bindings

    static func defaults(for system: GameSystem) -> Bindings
}

@available(*, deprecated, renamed: "ControlsInputSource", message: "foo")
protocol ControllerInputSourceProtocol {
    associatedtype Bindings: Codable & Sendable

    static var sourceKind: ControlsInputSourceKind { get }

    static func defaultBindings(for system: GameSystem) -> Bindings
    func decode(_ data: consuming ControlsConfigData, decoder: JSONDecoder) throws -> Bindings
    func encode(_ newValue: Bindings, encoder: JSONEncoder) throws -> ControlsConfigData
}

@MainActor
final class ControlBindingsManager {
    private let persistence: Persistence
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(persistence: Persistence) {
        self.persistence = persistence
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func load<S: InputSourceDescriptorProtocol>(
        for source: S,
        game: ObjectBox<GameObject>?,
        system: GameSystem
    ) -> S.Bindings {
        guard
            let game = game?.tryGet(in: persistence.mainContext),
            let controls = game.controls as? Set<ControlsConfigurationObject>,
            let config = controls.first(where: { config in
                config.system == system && config.kind == source.kind && config.sourceID == source.id
            }),
            let raw = config.data,
            let bindings = try? source.decode(.init(version: config.version, data: raw), decoder: decoder)
        else {
            return load(for: source, system: system)
        }
        return bindings
    }

    func load<S: InputSourceDescriptorProtocol>(for source: S, system: GameSystem) -> S.Bindings {
        let request = ControlsConfigurationObject.fetchRequest()
        request.fetchLimit = 1
        request.includesSubentities = false
        request.predicate = if let sourceID = source.id {
            NSPredicate(
                format: "rawSystem = %d AND rawKind = %d AND sourceID = %@",
                system.rawValue,
                source.kind.rawValue,
                sourceID
            )
        } else {
            NSPredicate(
                format: "rawSystem = %d AND rawKind = %d",
                system.rawValue,
                source.kind.rawValue
            )
        }

        guard
            let config = try? persistence.mainContext.fetch(request).first,
            let raw = config.data,
            let bindings = try? source.decode(.init(version: config.version, data: raw), decoder: decoder)
        else {
            return S.defaults(for: system)
        }
        return bindings
    }
}
