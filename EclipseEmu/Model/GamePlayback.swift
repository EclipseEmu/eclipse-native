import Combine
import Foundation
import CoreData
import SwiftUI
import EclipseKit

enum GamePlaybackState {
    case none
    case playing(EmulationViewModel)
}

enum GamePlaybackMissingFile: Equatable {
    case none
    case rom(ObjectBox<GameObject>)
    case saveState(ObjectBox<SaveStateObject>)
}

enum GamePlaybackError: LocalizedError {
    case unknown(any Error)
    case badPermissions
    case failedToHash
    case hashMismatch(GamePlaybackMissingFile, String, URL)
    case missingCore
    case failedToReplaceROM
    case missingGame
    case missingFile(GamePlaybackMissingFile)

    case core(GameCoreCoordinatorError)

    var errorDescription: String? {
        switch self {
        case .badPermissions: "Missing Permissions"
        case .failedToHash: "Failed to Hash"
        case .failedToReplaceROM: "Failed to replace the ROM file."
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
        case .core(let error): error.errorDescription
        case .unknown(let error):
            if let localizedError = error as? LocalizedError {
                localizedError.errorDescription
            } else {
                "An Unknown Error Occurred"
            }
        case .missingGame:
            "This Save State is not associated with a game."
        }
    }
}

struct GamePlaybackData: Sendable {
    let core: CoreInfo
    let game: ObjectBox<GameObject>
    let saveState: ObjectBox<SaveStateObject>?
    let romPath: FileSystemPath
    let savePath: FileSystemPath
    let saveStatePath: FileSystemPath?
    let cheats: [GamePlaybackData.OwnedCheat]

    struct OwnedCheat: Identifiable, Equatable, Hashable {
        let id: ObjectIdentifier
        let code: String?
        let enabled: Bool
        let label: String?
        let priority: Int16
        let type: String?

        init(_ cheat: CheatObject) {
            self.id = cheat.id
            self.code = cheat.code
            self.enabled = cheat.enabled
            self.label = cheat.label
            self.priority = cheat.priority
            self.type = cheat.type
        }
    }
}

@MainActor
final class GamePlayback: ObservableObject {
    private let coreRegistry: CoreRegistry
    @Published var playbackState: GamePlaybackState = .none

    init(coreRegistry: CoreRegistry) {
        self.coreRegistry = coreRegistry
    }

    func play(game: GameObject, persistence: Persistence) async throws(GamePlaybackError) {
        guard let core = coreRegistry.get(for: game) else {
            throw GamePlaybackError.missingCore
        }
        guard await persistence.files.exists(path: game.romPath) else {
            throw GamePlaybackError.missingFile(.rom(.init(game)))
        }

        let cheats = (game.cheats as? Set<CheatObject>) ?? []
        do {
            let viewModel: EmulationViewModel = try await EmulationViewModel(
                coreInfo: core,
                game: game,
                saveState: nil,
                romPath: game.romPath,
                savePath: game.savePath,
                cheats: cheats.map(Cheat.init),
                persistence: persistence
            )
            self.playbackState = .playing(viewModel)
        } catch {
            throw .core(error)
        }
    }

    func play(state: SaveStateObject, persistence: Persistence) async throws(GamePlaybackError) {
        guard let game = state.game else { throw GamePlaybackError.missingGame }
        guard let core = coreRegistry.get(for: game) else {
            throw GamePlaybackError.missingCore
        }
        let files = persistence.files
        guard await files.exists(path: state.path) else {
            throw GamePlaybackError.missingFile(.saveState(.init(state)))
        }
        guard await files.exists(path: game.romPath) else {
            throw GamePlaybackError.missingFile(.rom(.init(game)))
        }

        let cheats = (game.cheats as? Set<CheatObject>) ?? []
        do {
            let viewModel: EmulationViewModel = try await EmulationViewModel(
                coreInfo: core,
                game: game,
                saveState: state,
                romPath: game.romPath,
                savePath: game.savePath,
                cheats: cheats.map(Cheat.init),
                persistence: persistence
            )
            self.playbackState = .playing(viewModel)
        } catch {
            throw .core(error)
        }
    }

    public func closeGame() {
        self.playbackState = .none
    }
}
