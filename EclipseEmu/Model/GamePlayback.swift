import Combine
import Foundation
import CoreData
import SwiftUI
import EclipseKit

enum GamePlaybackState {
    case none
    case playing(GamePlaybackData)
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
        case .missingCore: "There is either no available core for this system, or hasn't been set yet."
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
        case .missingGame:
            "This Save State is not associated with a game."
        }
    }
}

@MainActor
struct GamePlaybackData {
    let coreID: Core
	let system: System
    let game: GameObject
    let saveState: SaveStateObject?
    let romPath: FileSystemPath
    let savePath: FileSystemPath
    let cheats: [CoreCheat]
}

@MainActor
final class GamePlayback: ObservableObject {
    @Published var playbackState: GamePlaybackState = .none

	func play(game: GameObject, persistence: Persistence, coreRegistry: CoreRegistry) async throws(GamePlaybackError) {
        guard let core = coreRegistry.get(for: game) else {
            throw GamePlaybackError.missingCore
        }
        guard await persistence.files.exists(path: game.romPath) else {
            throw GamePlaybackError.missingFile(.rom(.init(game)))
        }

		let cheats = (game.cheats as? Set<CheatObject>) ?? []
		let data = GamePlaybackData (
			coreID: core,
			system: game.system,
			game: game,
			saveState: nil,
			romPath: game.romPath,
			savePath: game.savePath,
			cheats: cheats.compactMap(CoreCheat.init)
		)

		self.playbackState = .playing(data)
    }

    func play(state: SaveStateObject, persistence: Persistence, coreRegistry: CoreRegistry) async throws(GamePlaybackError) {
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
		let data = GamePlaybackData (
			coreID: core,
			system: game.system,
			game: game,
			saveState: state,
			romPath: game.romPath,
			savePath: game.savePath,
			cheats: cheats.compactMap(CoreCheat.init)
		)

		self.playbackState = .playing(data)
    }

    public func closeGame() {
        self.playbackState = .none
    }
}
