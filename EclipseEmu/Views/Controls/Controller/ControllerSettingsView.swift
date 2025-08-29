import SwiftUI
import GameController
import EclipseKit

struct ControllerSettingsView: View {
    @EnvironmentObject private var persistence: Persistence
    private let controller: GCController
    
    init(controller: GCController) {
        self.controller = controller
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("CONTROLLER_VENDOR")
                    Spacer()
                    Text(controller.vendorName ?? "CONTROLLER_VENDOR_UNKNOWN")
                }
                if let battery = controller.battery {
                    HStack {
                        Text("CONTROLLER_BATTERY")
                        Spacer()
                        Text(verbatim: "\(Int(battery.batteryLevel * 100))%")
                    }
                }
            }

            Section {
                ControlsSystemProfilesView(load: loadProfile, update: setProfile)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("CONTROLLER")
    }
    
    private func loadProfile(for system: System) async throws -> ControllerProfileObject? {
        let box = try await persistence.objects.getProfileForController(
            controllerID: controller.persistentID,
            system: system,
            game: nil
        )
        return box?.tryGet(in: persistence.mainContext)
    }
    
    private func setProfile(for system: System, to profile: ControllerProfileObject?) async throws {
        try await persistence.objects.setProfileForController(
            controllerID: controller.persistentID,
            system: system,
            game: nil,
            to: profile.map(ObjectBox.init)
        )
    }
}

#Preview {
    ControllerSettingsView(controller: .withExtendedGamepad())
}
