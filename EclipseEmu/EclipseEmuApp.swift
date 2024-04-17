import SwiftUI

@main
struct EclipseEmuApp: App {
    // FIXME: once the models are finalized, make this use shared
    let persistenceController = PersistenceController.preview
    @StateObject var playGameAction = PlayGameAction()
    
    var body: some Scene {
        WindowGroup {
            if let game = playGameAction.game {
                EmulationView()
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
