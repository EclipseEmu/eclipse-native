import SwiftUI
import GameController
import Combine
import EclipseKit

class EmulationViewModel: ObservableObject {
    var coreCoordinator: GameCoreCoordinator
    var game: Game
    
    @Published var width: CGFloat = 0.0
    @Published var height: CGFloat = 0.0
    
    @Published var isMenuVisible = false
    @Published var isQuitDialogShown = false
    @Published var isRestartDialogShown = false
    @Published var volume: Float = 0.0
    
    init(core: GameCore, game: Game) {
        self.game = game
        self.coreCoordinator = try! GameCoreCoordinator(core: core, system: game.system)
    }
}

fileprivate struct ReorderingControllersRequest: Identifiable {
    var id = UUID()
    var maxPlayers: UInt8
    var players: [GameInputCoordinator.Player]
    var finish: ([GameInputCoordinator.Player]) -> Void
}

struct EmulationView: View, GameInputCoordinatorDelegate {
    @FocusState var focused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.playGame) var playGame
    @StateObject var model: EmulationViewModel
    @State fileprivate var reorderingControllersRequest: ReorderingControllersRequest?
    
    
    init(game: Game, core: GameCore) {
        self._model = StateObject(wrappedValue: EmulationViewModel(core: core, game: game))
    }
    
    var body: some View {
        ZStack {
            EmulationGameScreen(emulation: model.coreCoordinator)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .aspectRatio(model.width / model.height, contentMode: .fit)
            
            #if canImport(UIKit)
            TouchControlsView($menuModel.isMenuVisible, coreCoordinator: menuModel.coreCoordinator).opacity(0.6)
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
        .sheet(isPresented: $menuModel.isMenuVisible) {
            EmulationMenuView(model: menuModel)
                .presentationDetents([.medium])
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
            guard let romPath = self.model.game.romPath else {
                return
            }
            await self.model.coreCoordinator.start(gameUrl: romPath)
            self.model.width = await self.model.coreCoordinator.width
            self.model.height = await self.model.coreCoordinator.height
        }
        .task {
            await self.model.coreCoordinator.play()
        }
        .onDisappear {
            Task {
                await self.model.coreCoordinator.pause()
            }
        }
        .confirmationDialog("Quit Game", isPresented: $model.isQuitDialogShown) {
            Button("Quit", role: .destructive) {
                Task {
                    await playGame.closeGame()
                }
            }
        } message: {
            Text("Any unsaved progress will be lost.")
        }
        .sheet(item: $reorderingControllersRequest) {
            if let request = self.reorderingControllersRequest {
                request.finish(request.players)
            }
        } content: { request in
            ScrollView {
                ForEach(request.players) { player in
                    Text(player.displayName)
                }
            }
        }
    }
    
    func reorderControllers(players: inout [GameInputCoordinator.Player], maxPlayers: UInt8) async {
        await self.model.coreCoordinator.pause()
        
        // TODO: present UI and await for it to close to handle the reordering of the players
        players = await withCheckedContinuation { continuation in
            self.reorderingControllersRequest = .init(maxPlayers: maxPlayers, players: players, finish: { newPlayers in
                continuation.resume(returning: newPlayers)
            })
        }
        
        await self.model.coreCoordinator.play()
    }
}
