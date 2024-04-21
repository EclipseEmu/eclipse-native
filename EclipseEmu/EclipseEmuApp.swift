import SwiftUI

@main
struct EclipseEmuApp: App {
    // FIXME: once the models are finalized, make this use shared
    let persistenceController = PersistenceController.preview
    @StateObject var playGameAction = PlayGameAction()
    static let cores: GameCoreRegistry = {
        let dummyCore = DummyCore()
        
        let registry = GameCoreRegistry(cores: [dummyCore])
        registry.registerDefaults(id: dummyCore.id, for: .gb)
        registry.registerDefaults(id: dummyCore.id, for: .gbc)
        registry.registerDefaults(id: dummyCore.id, for: .gba)
        registry.registerDefaults(id: dummyCore.id, for: .nes)
        registry.registerDefaults(id: dummyCore.id, for: .snes)
        
        return registry
    }()
    
    var body: some Scene {
        WindowGroup {
            if let context = playGameAction.context {
                EmulationView(game: context.game, core: context.core)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environment(\.playGame, playGameAction)
            } else {
                LibraryView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environment(\.playGame, playGameAction)
            }
        }
    }
}
