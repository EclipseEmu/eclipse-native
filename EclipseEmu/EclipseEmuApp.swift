import mGBAEclipseCore
import SwiftUI

@main
struct EclipseEmuApp: App {
    // FIXME: once the models are finalized, make this use shared
    let persistenceCoordinator = PersistenceCoordinator.preview
    @StateObject var playGameAction = PlayGameAction()
    static let cores: GameCoreRegistry = {
        let mGBACore = mGBAEclipseCore.coreInfo
        let registry = GameCoreRegistry(cores: [mGBACore])
        registry.registerDefaults(id: mGBACore.id, for: .gba)
        return registry
    }()

    #if os(macOS)
    @State var selection: SidebarView.Selection = .library
    #endif

    var body: some Scene {
        WindowGroup {
            if let model = self.playGameAction.model {
                EmulationView(model: model)
            } else {
                #if !os(macOS)
                TabView {
                    LibraryView()
                        .tabItem {
                            Label("Library", systemImage: "books.vertical")
                        }
                    GameCollectionsView()
                        .tabItem {
                            Label("Collections", systemImage: "square.stack")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                #else
                NavigationSplitView {
                    SidebarView(selection: $selection)
                } detail: {
                    switch selection {
                    case .library:
                        LibraryView()
                    case .collection(let gameCollection):
                        GameCollectionView(collection: gameCollection)
                    }
                }
                #endif
            }
        }
        .environment(\.managedObjectContext, persistenceCoordinator.container.viewContext)
        .environment(\.persistenceCoordinator, persistenceCoordinator)
        .environment(\.playGame, playGameAction)

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, persistenceCoordinator.container.viewContext)
                .environment(\.persistenceCoordinator, persistenceCoordinator)
                .environment(\.playGame, playGameAction)
        }
        #endif
    }
}
