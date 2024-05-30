import SwiftUI
//import DummyCore
import mGBAEclipseCore

@main
struct EclipseEmuApp: App {
    // FIXME: once the models are finalized, make this use shared
    let persistenceCoordinator = PersistenceCoordinator.preview
    @StateObject var playGameAction = PlayGameAction()
    static let cores: GameCoreRegistry = {
//        let dummyCore = DummyCore.coreInfo
        let mGBACore = mGBAEclipseCore.coreInfo
        let registry = GameCoreRegistry(cores: [mGBACore])
//        registry.registerDefaults(id: dummyCore.id, for: .gb)
//        registry.registerDefaults(id: dummyCore.id, for: .gbc)
        registry.registerDefaults(id: mGBACore.id, for: .gba)
//        registry.registerDefaults(id: dummyCore.id, for: .nes)
//        registry.registerDefaults(id: dummyCore.id, for: .snes)
        
        return registry
    }()
    
    var body: some Scene {
        WindowGroup {
            if let model = self.playGameAction.model {
                EmulationView(model: model)
            } else {
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
            }
        }
        .environment(\.managedObjectContext, self.persistenceCoordinator.container.viewContext)
        .environment(\.persistenceCoordinator, self.persistenceCoordinator)
        .environment(\.playGame, self.playGameAction)
    }
}
