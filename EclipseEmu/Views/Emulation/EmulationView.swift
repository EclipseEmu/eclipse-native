import SwiftUI
import GameController
import Combine
import EclipseKit

class EmulationViewModel: ObservableObject, GameInputCoordinatorDelegate  {
    var coreCoordinator: GameCoreCoordinator!
    var game: Game
    
    @Published var width: CGFloat = 0.0
    @Published var height: CGFloat = 0.0
    
    @Published var playerOrderChangeRequest: PlayerOrderChangeRequest?
    @Published var isMenuVisible = false
    @Published var isQuitDialogShown = false
    @Published var isRestartDialogShown = false
    @Published var volume: Float = 0.0
    
    init(core: GameCoreInfo, game: Game) {
        self.game = game
        // FIXME: this is expensive here...
        self.coreCoordinator = try! GameCoreCoordinator(coreInfo: core, system: game.system, reorderControls: self.reorderControllers)
    }
    
    @MainActor
    func setScreenSize(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    func reorderControllers(players: inout [GameInputCoordinator.Player], maxPlayers: UInt8) async {
        await self.coreCoordinator.pause()
        
        players = await withCheckedContinuation { continuation in
            self.playerOrderChangeRequest = .init(maxPlayers: maxPlayers, players: players) { newPlayers in
                continuation.resume(returning: newPlayers)
            }
        }
        
        await self.coreCoordinator.play()
    }
}

struct EmulationView: View {
    @FocusState var focused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.playGame) var playGame
    @StateObject var model: EmulationViewModel
    
    init(model: EmulationViewModel) {
        self._model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ZStack {
            EmulationGameScreen(emulation: model.coreCoordinator)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .aspectRatio(model.width / model.height, contentMode: .fit)
                #if canImport(UIKit)
                .padding(.bottom, verticalSizeClass == .compact ? 0 : 153.0)
                #endif
            
            #if canImport(UIKit)
            TouchControlsView($model.isMenuVisible, coreCoordinator: model.coreCoordinator).opacity(0.6)
            #elseif os(macOS)
            EmulationMenuViewBar(model: model)
            #endif
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .focused($focused)
        .modify {
            if #available(iOS 17.0, macOS 14.0, *) {
                $0.focusable().focusEffectDisabled().onKeyPress { _ in return .handled }
            } else {
                $0
            }
        }
        .background(.black)
        #if !os(macOS)
        .sheet(isPresented: $model.isMenuVisible) {
            EmulationMenuView(model: model)
                .modify {
                    if #available(iOS 16.0, *) {
                        $0.presentationDetents([.medium])
                    } else {
                        $0
                    }
                }
        }
        #else
        .onHover { state in
            withAnimation {
                self.model.isMenuVisible = state
            }
        }
        #endif
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                Task {
                    await self.model.coreCoordinator.play()
                }
            default:
                Task {
                    await self.model.coreCoordinator.pause()
                }
            }
        }
        .onAppear {
            focused = true
        }
        .firstTask {
            guard let romPath = self.model.game.romPath, romPath.startAccessingSecurityScopedResource() else {
                return
            }
            await self.model.coreCoordinator.start(gamePath: romPath, savePath: nil);
            
            let width = await self.model.coreCoordinator.width
            let height = await self.model.coreCoordinator.height
            self.model.setScreenSize(width: width, height: height)
        }
        .sheet(item: $model.playerOrderChangeRequest) { request in
            ReorderControllersView(request: request)
        }
        .confirmationDialog("Quit Game", isPresented: $model.isQuitDialogShown) {
            Button("Quit", role: .destructive) {
                Task {
                    await self.model.coreCoordinator.stop()
                    await playGame.closeGame()
                    if let romPath = self.model.game.romPath {
                        romPath.stopAccessingSecurityScopedResource()
                    }
                }
            }
        } message: {
            Text("Any unsaved progress will be lost.")
        }
    }
}
