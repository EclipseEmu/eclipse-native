import CoreData
import EclipseKit
import SwiftUI

final class PlayGameAction: ObservableObject {
    @Published var model: EmulationViewModel?

    enum MissingFile {
        case none
        case rom
        case saveState
    }

    enum Failure: LocalizedError {
        case missingCore
        case missingFile(MissingFile)
    }

    public func callAsFunction(game: Game, saveState: SaveState?, persistence: PersistenceCoordinator) async throws {
        guard let core = await EclipseEmuApp.cores.get(for: game) else {
            throw Failure.missingCore
        }

        let data = try GameManager.emulationData(for: game, in: persistence)

        let missingFile = await withUnsafeBlockingContinuation { continuation in
            if let saveStatePath = saveState?.path(in: persistence) {
                guard persistence.fileExists(path: saveStatePath) else {
                    return continuation.resume(returning: MissingFile.saveState)
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
