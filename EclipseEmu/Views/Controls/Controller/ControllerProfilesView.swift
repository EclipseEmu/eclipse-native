import SwiftUI
import EclipseKit
import CoreData
import GameController

struct ControllerProfilesView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        ControlsProfilesView<InputSourceControllerDescriptor, _>(title: "CONTROLLER_PROFILES_TITLE", settings: $settings.controllerSystemProfiles) {
            Section("CONNECTED_CONTROLLERS") {
                ForEachConnectedControllers { controller in
                    NavigationLink(to: .controllerSettings(controller)) {
                        Label(controller.vendorName ?? "UNKNOWN_CONTROLLER", systemImage: controller.symbol)
                    }
                } isEmpty: {
                    EmptyMessage(title: "NO_CONNECTED_CONTROLLERS_TITLE", message: "NO_CONNECTED_CONTROLLERS_MESSAGE")
                }
            }
        }
    }
}

#Preview {
    ControllerProfilesView()
}
