import EclipseKit
import Foundation

@MainActor
final class EmulationViewModel<Core: CoreProtocol>: ObservableObject {
    @Published var game: GameObject
    let persistence: Persistence
    let settings: Settings
    let coordinator: CoreCoordinator<Core>
    let playback: GamePlayback
    
#if canImport(UIKit)
    let touchMappings: TouchMappings
#endif
    let stopAccessingRomFile: Bool
    let stopAccessingSaveFile: Bool
    
#if os(macOS)
    @Published var menuBarIsVisible: Bool = true
    @Published var menuBarHideTask: Task<Void, Never>?
    @Published var menuBarHideTaskInstant: ContinuousClock.Instant = .now
#endif

    @Published var isLoadStateViewOpen: Bool = false {
        didSet {
            Task {
                if isLoadStateViewOpen {
                    await coordinator.pause(reason: .pendingUserInput)
                } else {
                    await coordinator.play(reason: .pendingUserInput)
                }
            }
        }
    }

    @Published var isPlaying: Bool = true {
        didSet {
            Task {
                if isPlaying {
                    await coordinator.play(reason: .paused)
                } else {
                    await coordinator.pause(reason: .paused)
                }
            }
        }
    }
    
    @Published var volume: Float {
        didSet {
            Task {
                await coordinator.audio.setVolume(to: volume)
            }
        }
    }
    
#if os(iOS)
    @Published var ignoreSilentMode: Bool {
        didSet {
            CoreAudioRenderer.ignoreSilentMode(ignoreSilentMode)
        }
    }
#endif
    
    @Published var speed: EmulationSpeed = .x1_00 {
        didSet {
            Task {
                await coordinator.setFastForward(to: speed)
            }
        }
    }
    
#if canImport(UIKit)
    init(
        game: GameObject,
        persistence: Persistence,
        settings: Settings,
        coordinator: CoreCoordinator<Core>,
        playback: GamePlayback,
        touchMappings: TouchMappings,
        stopAccessingRomFile: Bool,
        stopAccessingSaveFile: Bool
    ) {
        self.game = game
        self.persistence = persistence
        self.settings = settings
        self.coordinator = coordinator
        self.playback = playback
        self.touchMappings = touchMappings
        self.ignoreSilentMode = settings.ignoreSilentMode
        self.volume = Float(settings.volume)
        self.stopAccessingRomFile = stopAccessingRomFile
        self.stopAccessingSaveFile = stopAccessingSaveFile
        CoreAudioRenderer.ignoreSilentMode(ignoreSilentMode)
    }
#else
    init(
        game: GameObject,
        persistence: Persistence,
        settings: Settings,
        coordinator: CoreCoordinator<Core>,
        playback: GamePlayback,
        stopAccessingRomFile: Bool,
        stopAccessingSaveFile: Bool
    ) {
        self.game = game
        self.persistence = persistence
        self.settings = settings
        self.coordinator = coordinator
        self.playback = playback
        self.volume = Float(settings.volume)
        self.stopAccessingRomFile = stopAccessingRomFile
        self.stopAccessingSaveFile = stopAccessingSaveFile
    }
#endif

    func sceneMadeActive() async {
        await coordinator.play(reason: .backgrounded)
    }
    
    func sceneHidden() async {
        guard await coordinator.state != .backgrounded else { return }
        await coordinator.pause(reason: .backgrounded)
        guard await coordinator.state == .backgrounded else { return }
        try? await saveState(isAuto: true)
    }
    
    func saveState(isAuto: Bool = false) async throws {
        do {
            try await persistence.objects.createSaveState(isAuto: isAuto, for: .init(game), with: coordinator)
        } catch {
            print("creating auto save state failed:", error)
            throw error
        }
    }
    
    func quit() async {
        try? await saveState(isAuto: true)
        await coordinator.stop()
        playback.closeGame()
    }
}
