import SwiftUI
import mGBAEclipseCore

@main
struct EclipseEmuApp: App {
    let persistence = Persistence(inMemory: true)
    @StateObject var playGameAction = PlayGameAction()

    static let cores: GameCoreRegistry = {
        let registry = GameCoreRegistry(cores: [mGBACoreInfo])
        registry.registerDefaults(id: mGBACoreInfo.id, for: .gba)
        return registry
    }()

    var body: some Scene {
        WindowGroup {
            if let model = self.playGameAction.model {
                EmulationView(model: model)
                    .persistence(self.persistence)
            } else {
                LibraryView()
                    .persistence(self.persistence)
            }
        }
        .environment(\.playGame, playGameAction)

        #if os(macOS)
        Settings {
            SettingsView()
                .persistence(self.persistence)
                .environment(\.playGame, playGameAction)
        }
        #endif
    }
}
