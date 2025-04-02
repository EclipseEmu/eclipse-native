import SwiftUI
import AVFoundation
import EclipseKit

enum EmulationViewState {
    case loading
    case quitting
    case error(Error)
    case loaded(GameCoreCoordinator)
}

enum EmulationViewError: LocalizedError {
    case romMissing
    case romBadAccess

    var errorDescription: String? {
        switch self {
        case .romBadAccess:
            "Failed to get access to the ROM. Check if the file has been moved or deleted."
        case .romMissing:
            "This game does not have a ROM associated with it."
        }
    }
}

@MainActor
final class EmulationViewModel: ObservableObject {
    @Published var game: Game
    let persistence: Persistence
    let core: GameCoreCoordinator

    @Published var aspectRatio: CGFloat = 1.0

    @Published var isQuitConfirmationShown = false
    @Published var isSaveStateViewShown = false

    @Published var volume: Float = 0.0 {
        didSet {
            Task {
                await core.audio.setVolume(to: self.volume)
            }
        }
    }

    @Published var isFastForwarding: Bool = false {
        didSet {
            Task {
                await core.setFastForward(enabled: self.isFastForwarding)
            }
        }
    }

    init(
        coreInfo: CoreInfo,
        game: Game,
        saveState: SaveState?,
        romPath: FileSystemPath,
        savePath: FileSystemPath,
        cheats: [OwnedCheat],
        persistence: Persistence
    ) async throws(GameCoreCoordinatorError) {
        self.game = game
        self.persistence = persistence
        self.core = try await GameCoreCoordinator(
            coreInfo: coreInfo,
            game: .init(game),
            system: game.system,
            bindingsManager: .init(persistence: persistence)
        )
        self.aspectRatio = core.width / core.height
        self.volume = 0.5

        let romPath = persistence.files.url(for: romPath)
        let savePath = persistence.files.url(for: savePath)
        await core.start(gamePath: romPath, savePath: savePath)

        if let failedCheats = await core.setCheats(cheats: cheats) {
            // FIXME: figure out what to do with these
            print("failed to set the following cheats:", failedCheats)
        }
        if let saveState {
            _ = await core.loadState(for: persistence.files.url(for: saveState.path))
        }
        try? await persistence.objects.updateDatePlayed(game: .init(self.game))
    }

    func renderingSurfaceCreated(surface: CAMetalLayer) {
        core.attach(surface: surface)
    }

    func quit(playback: GamePlayback) async {
        try? await persistence.objects.createSaveState(isAuto: true, for: .init(game), with: core)
        await core.stop()
        playback.closeGame()
    }

    func sceneMadeActive() async {
        await core.play(reason: .backgrounded)
    }

    func sceneHidden() async {
        guard await core.state != .backgrounded else { return }
        await core.pause(reason: .backgrounded)
        guard await core.state == .backgrounded else { return }

        do {
            try await persistence.objects.createSaveState(isAuto: true, for: .init(game), with: core)
        } catch {
            print("creating save state failed:", error)
        }
    }

    func reorderControllers(players: inout [GameInputPlayer], maxPlayers: UInt8) async {
        await core.pause(reason: .pendingUserInput)
        // FIXME: reorder controls here
        await core.play(reason: .pendingUserInput)
    }

    func togglePlayPause() async {
        if await core.state == .running {
            await core.pause(reason: .paused)
        } else {
            await core.play(reason: .paused)
        }
    }

    func saveState() {
        Task {
            do {
                try await persistence.objects.createSaveState(isAuto: false, for: .init(game), with: core)
            } catch {
                // FIXME: show a message here
                print("creating save state failed:", error)
            }
        }
    }
}
