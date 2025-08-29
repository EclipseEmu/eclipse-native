import SwiftUI
import EclipseKit
import GameController

struct GameSettingsView: View {
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var coreRegistry: CoreRegistry
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    @ObservedObject var game: GameObject

    var body: some View {
        Form {
            Section {
                CorePickerView("CORE_OVERRIDE", selection: $game.core, system: game.system, coreRegistry: coreRegistry)
            } footer: {
                Text("CORE_OVERRIDE_DESCRIPTION")
            }
            
            Section {
#if canImport(UIKit)
                ControlsProfilePicker(profile: $game.touchProfile, defaultProfileLabel: "USING_GLOBAL_PROFILE", system: game.system) {
                    Text("TOUCH_PROFILE")
                }
#endif
                ControlsProfilePicker(profile: $game.keyboardProfile, defaultProfileLabel: "USING_GLOBAL_PROFILE", system: game.system) {
                    Text("KEYBOARD_PROFILE")
                }
            }
            
            Section {
                ControlsProfilePicker(profile: $game.controllerProfile, defaultProfileLabel: "USING_GLOBAL_PROFILE", system: game.system) {
                    Text("ANY_CONTROLLER_PROFILE")
                }
                ForEachConnectedControllers { controller in
                    GameSpecificControllerProfileView(game: game, controller: controller)
                }
            } header: {
                Text("CONTROLLER_PROFILES")
            } footer: {
                Text("CONTROLLER_PROFILES_FOOTER")
            }
        }
        .onReceive(game.objectWillChange, perform: gameUpdated)
        .formStyle(.grouped)
        .navigationTitle("GAME_SETTINGS")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            CancelButton("DONE", action: dismiss.callAsFunction)
        }
    }
    
    func gameUpdated() {
        do {
            // FIXME: Move to background context
            try persistence.mainContext.saveIfNeeded()
        } catch {
            print(error)
        }
    }
}

private struct GameSpecificControllerProfileView: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject var game: GameObject
    let controller: GCController
    
    var body: some View {
        LazyControlsProfilePicker("USING_GLOBAL_PROFILE", system: game.system, load: loadProfile, update: setProfile) {
            Label(controller.vendorName ?? "UNKNOWN_CONTROLLER", systemImage: controller.symbol)
        }
    }
    
    func loadProfile(for system: System) async throws -> ControllerProfileObject? {
        let box = try await persistence.objects.getProfileForController(
            controllerID: controller.persistentID,
            system: system,
            game: .init(game)
        )
        return box?.tryGet(in: persistence.mainContext)
    }
    
    func setProfile(for system: System, to profile: ControllerProfileObject?) async throws {
        try await persistence.objects.setProfileForController(
            controllerID: controller.persistentID,
            system: system,
            game: .init(game),
            to: profile.map(ObjectBox.init)
        )
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .previewStorage) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        NavigationStack {
            GameSettingsView(game: game)
        }
    }
}
