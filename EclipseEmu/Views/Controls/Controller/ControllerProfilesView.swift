import SwiftUI
import EclipseKit
import CoreData
import GameController

struct ControllerProfilesView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        ControlsProfilesView(title: "CONTROLLER_PROFILES_TITLE", settings: $settings.controllerSystemProfiles) {
            ConnectedControllersView()
        }
    }
}

#Preview {
    ControllerProfilesView()
}
