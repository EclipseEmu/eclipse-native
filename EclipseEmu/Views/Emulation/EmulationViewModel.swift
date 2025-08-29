import EclipseKit
import SwiftUI

@MainActor
final class EmulationViewModel<Core: CoreProtocol>: ObservableObject {
#if canImport(UIKit)
    typealias TouchMappingsHandle = TouchMappings
#else
    typealias TouchMappingsHandle = Void
#endif
    
    @Published var game: GameObject
    let persistence: Persistence
    let settings: Settings
    let coordinator: CoreCoordinator<Core>
    let playback: GamePlayback
    let touchMappings: TouchMappingsHandle
    let stopAccessingRomFile: Bool
    let stopAccessingSaveFile: Bool
    
    @Published var message: LocalizedStringKey? = nil
    @Published var messageHideTask: Task<Void, Never>?
    
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
            settings.volume = Double(volume)
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
    
    init(
        game: GameObject,
        persistence: Persistence,
        settings: Settings,
        coordinator: CoreCoordinator<Core>,
        playback: GamePlayback,
        touchMappings: TouchMappingsHandle,
        stopAccessingRomFile: Bool,
        stopAccessingSaveFile: Bool
    ) {
        self.game = game
        self.persistence = persistence
        self.settings = settings
        self.coordinator = coordinator
        self.playback = playback
        self.touchMappings = touchMappings
        self.volume = Float(settings.volume)
        self.stopAccessingRomFile = stopAccessingRomFile
        self.stopAccessingSaveFile = stopAccessingSaveFile
#if os(iOS)
        self.ignoreSilentMode = settings.ignoreSilentMode
        CoreAudioRenderer.ignoreSilentMode(ignoreSilentMode)
#endif
        Task {
            await self.coordinator.audio.setVolume(to: self.volume)
        }
    }
    
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
            self.showMessage("MSG_SAVE_STATE_CREATED")
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
    
    @inlinable
    func gameSaved(_: Notification) {
        self.showMessage("MSG_GAME_SAVED")
    }
    
    func showMessage(_ message: LocalizedStringKey, duration: ContinuousClock.Duration = .seconds(2)) {
        self.message = message
        self.messageHideTask?.cancel()
        self.messageHideTask = Task {
            do {
                try await Task.sleep(for: duration)
                self.message = nil
            } catch {}
        }
    }
}
