import Foundation
import EclipseKit

/// A Swift-safe representation of GameCoreInfo
final class CoreInfo: Identifiable, Equatable, Hashable, Sendable {
    // A unique identifier for this core.
    let id: String
    /// The user-shown name of the core.
    let name: String
    /// The developer(s) responsible for the core.
    let developer: String
    /// The version of the core.
    let version: String
    /// The URL to the core's source code repository.
    let sourceCodeUrl: URL?
    /// The systems this core supports.
    let supportedSystems: [GameSystem]
    /// The settings this core provides.
    let settings: CoreSettingsDefinition
    /// A list of supported cheat formats.
    let cheatFormats: [CheatFormat]

    /// A function to do any initialization.
    ///
    /// - Parameters
    ///    - system: The system to use
    ///    - callbacks: The core callbacks
    /// - Returns: an instance of an EKCore.
    let setup: @convention(c) (GameSystem, UnsafePointer<GameCoreCallbacks>?) -> UnsafeMutablePointer<GameCore>?

    init(raw: GameCoreInfo) {
        self.id = String(cString: raw.id)
        self.name = String(cString: raw.name)
        self.developer = String(cString: raw.developer)
        self.version = String(cString: raw.version)
        self.sourceCodeUrl = URL(string: String(cString: raw.sourceCodeUrl))
        self.supportedSystems = Array(UnsafeBufferPointer(start: raw.supportedSystems, count: Int(raw.supportedSystemsCount)))
        self.settings = .init(raw: raw.settings)
        self.cheatFormats = UnsafeBufferPointer(start: raw.cheatFormats, count: Int(raw.cheatFormatsCount)).map(CheatFormat.init)
        self.setup = raw.setup
    }

    static func == (lhs: CoreInfo, rhs: CoreInfo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
