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
        case missingFile(MissingFile)
        case unknown(any Error)

        var errorDescription: String? {
            switch self {
            case .badPermissions: "Missing Permissions"
            case .failedToHash: "Failed to Hash"
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

    public func callAsFunction(game: Game, saveState: SaveState?, persistence: PersistenceCoordinator) async throws {
        guard let core = await EclipseEmuApp.cores.get(for: game) else {
            throw Failure.missingCore
        }

        let data = try GameManager.emulationData(for: game, in: persistence)

        let missingFile = await withUnsafeBlockingContinuation { continuation in
            if let saveState {
                guard persistence.fileExists(path: saveState.path(in: persistence)) else {
                    return continuation.resume(returning: MissingFile.saveState(saveState.objectID))
                }
            }
            guard persistence.fileExists(path: data.romPath) else {
                return continuation.resume(returning: MissingFile.rom)
            }
            return continuation.resume(returning: MissingFile.none)
        }

        guard missingFile == .none else {
            throw Failure.missingFile(missingFile)
        }

        let model = EmulationViewModel(
            coreInfo: core,
            game: game,
            saveState: saveState,
            emulationData: data,
            persistence: persistence
        )

        await MainActor.run {
            self.model = model
        }
    }

    public func closeGame() async {
        await MainActor.run {
            self.model = nil
        }
    }
}

// MARK: setup @Environment

private struct PlayGameActionKey: EnvironmentKey {
    static let defaultValue: PlayGameAction = .init()
}

extension EnvironmentValues {
    var playGame: PlayGameAction {
        get { self[PlayGameActionKey.self] }
        set { self[PlayGameActionKey.self] = newValue }
    }
}
