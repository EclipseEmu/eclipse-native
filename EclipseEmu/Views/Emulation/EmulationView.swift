import SwiftUI
import GameController
import Combine
import EclipseKit

class EmulationViewModel: ObservableObject {
    @Published var coreCoordinator: GameCoreCoordinator
    @Published var isMenuVisible = false
    @Published var isQuitDialogShown = false
    @Published var isRestartDialogShown = false
    @Published var volume: Float = 0.0
    
    private var anyCancellable: AnyCancellable? = nil

    init(core: GameCore, game: Game) {
        self.coreCoordinator = try! GameCoreCoordinator(core: core, system: game.system)
        anyCancellable = coreCoordinator.objectWillChange.receive(on: RunLoop.main).sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
    }
}

struct EmulationView: View {
    @FocusState var focused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.playGame) var playGame
    @StateObject var menuModel: EmulationViewModel
    
    init(game: Game, core: GameCore) {
        self._menuModel = StateObject(wrappedValue: EmulationViewModel(core: core, game: game))
    }
    
    var body: some View {
        ZStack {
            EmulationGameScreen(emulation: menuModel.coreCoordinator)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .aspectRatio(menuModel.coreCoordinator.width / menuModel.coreCoordinator.height, contentMode: .fit)
            
            #if canImport(UIKit)
            TouchControlsView($menuModel.isMenuVisible, coreCoordinator: menuModel.coreCoordinator).opacity(0.6)
            #elseif os(macOS)
            EmulationMenuViewBar(model: menuModel)
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
                self.menuModel.isMenuVisible = state
            }
        }
        #endif
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                Task {
                    await self.menuModel.coreCoordinator.play()
                }
            default:
                Task {
                    await self.menuModel.coreCoordinator.pause()
                }
            }
        }
        .onAppear {
            focused = true
        }
        .firstTask {
            await self.menuModel.coreCoordinator.start(gameUrl: URL(string: "https://hi.com")!)
        }
        .task {
            await self.menuModel.coreCoordinator.play()
        }
        .onDisappear {
            Task {
                await self.menuModel.coreCoordinator.pause()
            }
        }
        .confirmationDialog("Quit Game", isPresented: $menuModel.isQuitDialogShown) {
            Button("Quit", role: .destructive) {
                Task {
                    await playGame.closeGame()
                }
            }
        } message: {
            Text("Any unsaved progress will be lost.")
        }
    }
}
