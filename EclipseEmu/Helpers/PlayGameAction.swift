import CoreData
import EclipseKit
import SwiftUI

final class PlayGameAction: ObservableObject {
    @Published var model: EmulationViewModel?

    enum MissingFile: Equatable {
        case none
        case rom
        case saveState(NSManagedObjectID)
    }

    enum Failure: LocalizedError {
        case badPermissions
        case failedToHash
        case hashMismatch(MissingFile, String, URL)
        case missingCore
        case failedToReplaceRom
        case missingFile(MissingFile)
        case unknown(any Error)

        var errorDescription: String? {
            switch self {
            case .badPermissions: "Missing Permissions"
            case .failedToHash: "Failed to Hash"
            case .failedToReplaceRom: "Failed to replace the ROM file."
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

    @MainActor
    public func callAsFunction(game: Game, saveState: SaveState?, persistence: Persistence) async throws {
        guard let core = EclipseEmuApp.cores.get(for: game) else {
            throw Failure.missingCore
        }
        let fileSystem = persistence.files

        let cheats = (game.cheats as? Set<Cheat>) ?? []

        let data = EmulationData(
            romPath: fileSystem.url(for: game.romPath),
            savePath: fileSystem.url(for: game.savePath),
            cheats: cheats.map { EmulationData.OwnedCheat(cheat: $0) }
        )

        if let saveState {
            guard await persistence.files.exists(path: saveState.path) else {
                throw Failure.missingFile(MissingFile.saveState(saveState.objectID))
            }
        }
        guard await fileSystem.exists(path: game.romPath) else {
            throw Failure.missingFile(MissingFile.rom)
        }

        let model = EmulationViewModel(
            coreInfo: core,
            game: game,
            saveState: saveState,
            emulationData: data,
            persistence: persistence
        )

        self.model = model
    }

    @MainActor
    public func closeGame() async {
            self.model = nil
    }
}

// MARK: setup @Environment

private struct PlayGameActionKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: PlayGameAction = .init()
}

extension EnvironmentValues {
    var playGame: PlayGameAction {
        get { self[PlayGameActionKey.self] }
        set { self[PlayGameActionKey.self] = newValue }
    }
}
