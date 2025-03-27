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

@available(*, deprecated, renamed: "OldViewModel", message: "this is an old view model, do not use.")
@MainActor
final class EmulationViewModel: ObservableObject {
    @Published var state: EmulationViewState = .loading
    @Published var aspectRatio: CGFloat = 1.0

    @Published var isQuitConfirmationShown = false
    @Published var isSaveStateViewShown = false

    @Published var volume: Float = 0.0 {
        didSet {
            Task {
                guard case .loaded(let core) = state else { return }
                await core.audio.setVolume(to: self.volume)
            }
        }
    }

    @Published var isFastForwarding: Bool = false {
        didSet {
            Task {
                guard case .loaded(let core) = state else { return }
                await core.setFastForward(enabled: self.isFastForwarding)
            }
        }
    }

    private(set) var startTask: Task<Void, Never>?

    private let coreInfo: GameCoreInfo
    let game: Game
    private var initialSaveState: SaveState?
    private let persistence: Persistence
    private let emulationData: EmulationData

    init(
        coreInfo: GameCoreInfo,
        game: Game,
        saveState: SaveState?,
        emulationData: EmulationData,
        persistence: Persistence
    ) {
        self.coreInfo = coreInfo
        self.game = game
        self.persistence = persistence
        self.initialSaveState = saveState
        self.emulationData = emulationData
    }

    func renderingSurfaceCreated(surface: CAMetalLayer) {
        let system = game.system
        self.startTask = Task {
            do {
                let core = try await GameCoreCoordinator(coreInfo: self.coreInfo, system: system, reorderControls: self.reorderControllers)
                core.attach(surface: surface)

                self.aspectRatio = core.width / core.height
                self.volume = 0.5
                self.state = .loaded(core)

                await core.start(gamePath: self.emulationData.romPath, savePath: self.emulationData.savePath)
                if let failedCheats = await core.setCheats(cheats: self.emulationData.cheats) {
                    // FIXME: figure out what to do with these
                    print("failed to set the following cheats:", failedCheats)
                }
                if let initialSaveState = self.initialSaveState {
                    _ = await core.loadState(for: self.persistence.files.url(for: initialSaveState.path))
                    self.initialSaveState = nil
                }
                try await self.persistence.objects.updateDatePlayed(game: .init(self.game))
            } catch {
                self.state = .error(error)
            }
        }
    }

    func quit(playback: GamePlayback) async {
        if case .loaded(let core) = self.state {
            try? await persistence.objects.createSaveState(isAuto: true, for: .init(self.game), with: core)
            await core.stop()
        }
        self.state = .quitting
        await playback.closeGame()
    }

    func sceneMadeActive() async {
        guard case .loaded(let core) = self.state else { return }
        await core.play(reason: .backgrounded)
    }

    func sceneHidden() async {
        guard
            case .loaded(let core) = self.state,
            await core.state != .backgrounded
        else { return }

        await core.pause(reason: .backgrounded)

        guard await core.state == .backgrounded else { return }

        do {
            try await persistence.objects.createSaveState(isAuto: true, for: .init(self.game), with: core)
        } catch {
            print("creating save state failed:", error)
        }
    }

    func reorderControllers(players: inout [GameInputPlayer], maxPlayers: UInt8) async {
        guard case .loaded(let core) = self.state else { return }
        await core.pause(reason: .pendingUserInput)
        await core.play(reason: .pendingUserInput)
    }

    func togglePlayPause() async {
        guard case .loaded(let core) = self.state else { return }
        if await core.state == .running {
            await core.pause(reason: .paused)
        } else {
            await core.play(reason: .paused)
        }
    }

    func saveState() {
        guard case .loaded(let core) = self.state else { return }

        Task {
            // FIXME: show a message here
            do {
                try await persistence.objects.createSaveState(
                    isAuto: false,
                    for: .init(self.game),
                    with: core
                )
            } catch {
                print("creating save state failed:", error)
            }
        }
    }
}

