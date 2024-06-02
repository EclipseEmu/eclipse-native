import AVFoundation
import EclipseKit
import MetalKit
import SwiftUI

final class EmulationViewModel: ObservableObject {
    enum State {
        case loading
        case quitting
        case error(Error)
        case loaded(GameCoreCoordinator)
    }

    enum Failure: LocalizedError {
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

    @Published var state: State = .loading
    @Published var aspectRatio: CGFloat = 1.0

    @Published var isQuitConfirmationShown = false
    @Published var isSaveStateViewShown = false

    @Published var volume: Float = 0.0 {
        didSet {
            Task {
                guard case .loaded(let core) = state else { return }
                core.audio.volume = self.volume
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

    var startTask: Task<Void, Never>?

    var coreInfo: GameCoreInfo
    var game: Game
    var initialSaveState: SaveState?
    var persistence: PersistenceCoordinator
    var emulationData: GameManager.EmulationData

    init(
        coreInfo: GameCoreInfo,
        game: Game,
        saveState: SaveState?,
        emulationData: GameManager.EmulationData,
        persistence: PersistenceCoordinator
    ) {
        self.coreInfo = coreInfo
        self.game = game
        self.persistence = persistence
        self.initialSaveState = saveState
        self.emulationData = emulationData
    }

    func renderingSurfaceCreated(surface: CAMetalLayer) {
        self.startTask = Task.detached {
            do {
                let core = try await withUnsafeBlockingThrowingContinuation { continuation in
                    do {
                        let core = try GameCoreCoordinator(
                            game: self.game,
                            coreInfo: self.coreInfo,
                            system: self.game.system,
                            surface: surface,
                            reorderControls: self.reorderControllers
                        )
                        continuation.resume(returning: core)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }

                let aspectRatio = core.width / core.height
                await MainActor.run {
                    self.aspectRatio = aspectRatio
                    self.volume = 0.5
                    self.state = .loaded(core)
                }

                await core.start(gamePath: self.emulationData.romPath, savePath: self.emulationData.savePath)
                if let failedCheats = await core.setCheats(cheats: self.emulationData.cheats) {
                    // FIXME: figure out what to do with these
                    print("failed to set the following cheats:", failedCheats)
                }
                if let initialSaveState = self.initialSaveState {
                    _ = await core.loadState(for: initialSaveState.path(in: self.persistence))
                    self.initialSaveState = nil
                }
                GameManager.updateDatePlayed(for: self.game, in: self.persistence)
            } catch {
                await MainActor.run {
                    self.state = .error(error)
                }
            }
        }
    }

    func quit(playAction: PlayGameAction) async {
        if case .loaded(let core) = self.state {
            try? await SaveStateManager.create(isAuto: true, for: self.game, with: core, in: self.persistence)
            await core.stop()
        }
        await MainActor.run {
            self.state = .quitting
        }
        await playAction.closeGame()
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
            try await SaveStateManager.create(isAuto: true, for: self.game, with: core, in: self.persistence)
        } catch {
            print("creating save state failed:", error)
        }
    }

    func reorderControllers(players: inout [GameInputCoordinator.Player], maxPlayers: UInt8) async {
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

    func saveState(isAuto: Bool) {
        guard case .loaded(let core) = self.state else { return }

        Task {
            // FIXME: show a message here
            do {
                try await SaveStateManager.create(isAuto: isAuto, for: self.game, with: core, in: self.persistence)
            } catch {
                print("creating save state failed:", error)
            }
        }
    }
}

struct EmulationView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.playGame) var playGame
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @FocusState var focusState
    @StateObject var model: EmulationViewModel

    var body: some View {
        ZStack {
            GameScreenView(model: self.model)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .aspectRatio(self.model.aspectRatio, contentMode: .fit)
#if os(iOS)
                .padding(.bottom, self.verticalSizeClass == .compact ? 0 : 240)
#endif
                .onChange(of: self.scenePhase) { newPhase in
                    Task {
                        switch newPhase {
                        case .active:
                            await self.model.sceneMadeActive()
                        default:
                            await self.model.sceneHidden()
                        }
                    }
                }
                .focused(self.$focusState)
                .modify {
                    if #available(macOS 14.0, iOS 17.0, *) {
                        $0.focusable().focusEffectDisabled().onKeyPress { _ in
                            .handled
                        }
                    } else {
                        // FIXME: Figure out how to do the above but on older versions.
                        //  Really all its doing is disabling the "funk" sound.
                        $0
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .EKGameCoreDidSave), perform: { _ in
                    print("game saved")
                })

            switch self.model.state {
            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                    Button(role: .cancel) {
                        Task {
                            self.model.startTask?.cancel()
                            await self.model.quit(playAction: self.playGame)
                        }
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
#if !os(macOS)
                        .buttonBorderShape(.capsule)
#endif
                }
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Material.regular, ignoresSafeAreaEdges: .all)
            case .quitting:
                EmptyView()
            case .error(let error):
                ContentUnavailableMessage {
                    Label("Something went wrong", systemImage: "exclamationmark.octagon.fill")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Close") {
                        Task {
                            await self.model.quit(playAction: self.playGame)
                        }
                    }
                    .buttonStyle(.borderedProminent)
#if !os(macOS)
                        .buttonBorderShape(.capsule)
#endif
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Material.regular, ignoresSafeAreaEdges: .all)
            case .loaded(let core):
#if os(iOS)
                TouchControlsView { newValue in
                    core.inputs.handleTouchInput(newState: newValue)
                }.opacity(0.6)
#endif
                EmulationMenuView(
                    model: self.model,
                    menuButtonLayout: .init(
                        xOrigin: .leading,
                        yOrigin: .trailing,
                        x: 16,
                        y: 0,
                        width: 42,
                        height: 42,
                        hidden: false
                    ),
                    buttonOpacity: 0.6
                )
                .onAppear {
                    self.focusState = true
                }
            }
        }
        .onChange(of: self.model.isSaveStateViewShown, perform: { newValue in
            guard case .loaded(let core) = self.model.state else { return }
            Task {
                if newValue {
                    await core.pause(reason: .pendingUserInput)
                } else {
                    await core.play(reason: .pendingUserInput)
                }
            }
        })
        .sheet(isPresented: self.$model.isSaveStateViewShown) {
            CompatNavigationStack {
                SaveStatesListView(game: self.model.game, action: .loadState(self.model), haveDismissButton: true)
                    .navigationTitle("Load State")
#if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
            }
            .modify {
                if #available(iOS 16.0, *) {
                    $0.presentationDetents([.medium, .large])
                } else {
                    $0
                }
            }
        }
        .confirmationDialog("Quit Game", isPresented: self.$model.isQuitConfirmationShown) {
            Button("Quit", role: .destructive) {
                Task {
                    await self.model.quit(playAction: self.playGame)
                }
            }
        } message: {
            Text("Any unsaved progress will be lost.")
        }
        .background(Color.black, ignoresSafeAreaEdges: .all)
    }

    func loadState(saveState: SaveState, dismiss: DismissAction) {
        guard case .loaded(let core) = self.model.state else { return }

        dismiss()

        Task {
            let path = saveState.path(in: self.model.persistence)
            _ = await core.loadState(for: path)
        }
    }
}
