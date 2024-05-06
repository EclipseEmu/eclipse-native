import SwiftUI
import EclipseKit
import MetalKit
import AVFoundation

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
    
    @Published var volume: Float = 0.0 {
        didSet {
            Task {
                guard case .loaded(let core) = state else { return }
                core.audio.volume = volume
            }
        }
    }
    @Published var isFastForwarding: Bool = false {
        didSet {
            Task {
                guard case .loaded(let core) = state else { return }
                await core.setFastForward(enabled: isFastForwarding)
            }
        }
    }
    
    var coreInfo: GameCoreInfo
    var game: Game
    
    init(coreInfo: GameCoreInfo, game: Game) {
        self.coreInfo = coreInfo
        self.game = game
    }

    func renderingSurfaceCreated(surface: CAMetalLayer) async {
        do {
            let core = try GameCoreCoordinator(
                coreInfo: self.coreInfo,
                system: game.system,
                surface: surface,
                reorderControls: self.reorderControllers
            )
            
            let aspectRatio = core.width / core.height
            await MainActor.run {
                self.aspectRatio = aspectRatio
                self.volume = 0.5
                self.state = .loaded(core)
            }
            
            guard let romPath = game.romPath else { throw Failure.romMissing}
            guard romPath.startAccessingSecurityScopedResource() else { throw Failure.romBadAccess }
            await core.start(gamePath: romPath, savePath: game.savePath)
        } catch {
            await MainActor.run {
                self.state = .error(error)
            }
        }
    }
    
    func quit(playAction: PlayGameAction) async {
        if case .loaded(let core) = self.state {
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
        guard case .loaded(let core) = self.state else { return }
        await core.pause(reason: .backgrounded)
    }
    
    func reorderControllers(players: inout [GameInputCoordinator.Player], maxPlayers: UInt8) async -> Void {
        guard case .loaded(let core) = self.state else { return }
        await core.pause(reason: .pendingUserInput)
        await core.play(reason: .pendingUserInput)
    }
    
    func togglePlayPause() async {
        guard case .loaded(let core) = self.state else { return }
        if core.state == .running {
            await core.pause(reason: .paused)
        } else {
            await core.play(reason: .paused)
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
            GameScreenView(model: model)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .aspectRatio(model.aspectRatio, contentMode: .fit)
                #if os(iOS)
                .padding(.bottom, verticalSizeClass == .compact ? 0 : 240)
                #endif
                .onChange(of: scenePhase) { newPhase in
                    Task {
                        switch newPhase {
                        case .active:
                            await self.model.sceneMadeActive()
                        default:
                            await self.model.sceneHidden()
                        }
                    }
                }
                .focused($focusState)
                .modify {
                    if #available(macOS 14.0, iOS 17.0, *) {
                        $0.focusable().focusEffectDisabled().onKeyPress { _ in
                            return .handled
                        }
                    } else {
                        // FIXME: Figure out how to do the above but on older versions. Really all its doing is disabling the "funk" sound.
                        $0
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .EKGameCoreDidSave), perform: { _ in
                    print("game saved")
                })
           
            switch model.state {
            case .loading:
                VStack {
                    ProgressView()
                    Button(role: .cancel) {} label: {
                        Text("Cancel")
                    }.buttonStyle(.borderedProminent)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Material.regular, ignoresSafeAreaEdges: .all)
            case .quitting:
                EmptyView()
            case .error(let error):
                VStack {
                    Text("Something went wrong")
                    Text(error.localizedDescription)
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
                    model: model,
                    menuButtonLayout: .init(xOrigin: .leading, yOrigin: .trailing, x: 16, y: 0, width: 42, height: 42, hidden: false),
                    buttonOpacity: 0.6
                )
                .onAppear {
                    self.focusState = true
                }
            }
        }
        .confirmationDialog("Quit Game", isPresented: $model.isQuitConfirmationShown) {
            Button("Quit", role: .destructive) {
                Task {
                    await model.quit(playAction: playGame)
                }
            }
        } message: {
            Text("Any unsaved progress will be lost.")
        }
        .background(Color.black, ignoresSafeAreaEdges: .all)
    }
}
