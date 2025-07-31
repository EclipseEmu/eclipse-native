import SwiftUI
import GameController
import EclipseKit

struct ControllerSettingsView: View {
    let controller: GCController

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
    }
    
    func loadProfile(for system: System) -> ControllerProfileObject? {
        // FIXME: TODO
        return nil
    }
    
    func setProfile(for system: System, to profile: ControllerProfileObject?) {
        // FIXME: TODO
    }
}

#Preview {
    ControllerSettingsView(controller: .withExtendedGamepad())
}
