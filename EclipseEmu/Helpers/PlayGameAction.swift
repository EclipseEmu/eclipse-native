import CoreData
import EclipseKit
import SwiftUI

@MainActor
final class PlayGameAction: ObservableObject {
    @Published var model: EmulationViewModel?

    enum MissingFile: Equatable {
        case none
        case rom(NSManagedObjectID)
        case saveState(NSManagedObjectID)
    }

    enum Failure: LocalizedError {
        case badPermissions
        case failedToHash
        case romPathInvalid
        case savePathInvalid
        case hashMismatch(MissingFile, String, URL)
        case missingCore
        case missingFile(MissingFile)
        case unknown(any Error)

        var errorDescription: String? {
            switch self {
            case .badPermissions: "Missing Permissions"
            case .failedToHash: "Failed to Hash"
            case .romPathInvalid: "The path to the game's ROM failed to construct"
            case .savePathInvalid: "The path to the game's save failed to construct"
            case .hashMismatch(let kind, _, _):
                switch kind {
                case .rom: "The ROM file does not match the one that was originally used for this game. This may cause issues with save data, save states, and cheats."
                default: "E_HASH_MISMATCH"
                }
            case .missingCore: "Unknown Core"
            case .missingFile(let kind):
                switch kind {
                case .none: "Unknown File Missing"
                case .rom: "ROM is Missing"
                case .saveState: "Save State is Missing"
                }
            case .unknown(let error):
                if let localizedError = error as? LocalizedError {
                    localizedError.errorDescription
                } else {
                    "An Unknown Error Occurred"
                }
            }
        }
    }

    public func callAsFunction(game: Game, saveState: SaveState?, persistence: Persistence) async throws {
        guard let core = EclipseEmuApp.cores.get(for: game) else {
            throw Failure.missingCore
        }
        
        let data = try EmulationData(game: game)

        _ = try await (
            self.assertSaveStateExists(saveState: saveState),
            self.assertRomExists(romPath: data.romPath, gameId: game.objectID)
        )

        let model = EmulationViewModel(
            coreInfo: core,
            game: game,
            saveState: saveState,
            emulationData: data,
            persistence: persistence
        )

        self.model = model
    }

    public func closeGame() async {
        self.model = nil
    }

    private func assertSaveStateExists(saveState: SaveState?) async throws {
        guard let saveState else { return }
        guard await Files.shared.exists(file: .saveState(saveState.id)) else {
            throw Failure.missingFile(.saveState(saveState.objectID))
        }
    }

    private func assertRomExists(romPath: URL, gameId: NSManagedObjectID) async throws {
        guard await Files.shared.exists(url: romPath) else {
            throw Failure.missingFile(.rom(gameId))
        }
    }
}

// MARK: Setup @Environment

private struct PlayGameActionKey: EnvironmentKey {
    static let defaultValue = PlayGameAction()
}

extension EnvironmentValues {
    var playGame: PlayGameAction {
        get { self[PlayGameActionKey.self] }
        set { self[PlayGameActionKey.self] = newValue }
    }
}
