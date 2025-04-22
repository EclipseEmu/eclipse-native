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
                Text("DEFAULT")
                ForEach(GameSystem.concreteCases, id: \.rawValue) { system in
                    Text(system.string)
                }
            }

            Section {
                Button("RESET", role: .destructive, action: resetController)
            }
        }
        .formStyle(.grouped)
    }

    func resetController() {

    }
}

#Preview {
    ControllerSettingsView(controller: .withExtendedGamepad())
}
