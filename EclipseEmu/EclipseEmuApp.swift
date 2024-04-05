import SwiftUI

@main
struct EclipseEmuApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var playGameAction = PlayGameAction()
    
    var body: some Scene {
        WindowGroup {
            if playGameAction.game != nil {
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
