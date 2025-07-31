import SwiftUI
import EclipseKit

struct ControlsSystemProfilesView<ProfileObject: ControlsProfileObject>: View {
    let load: (System) -> ProfileObject?
    let update: (System, ProfileObject?) -> Void
    
    var body: some View {
        ForEach(System.concreteCases, id: \.rawValue) { system in
            ControlsProfileSystemPicker<ProfileObject>(system: system, load: load, update: update)
        }
    }
}

private struct ControlsProfileSystemPicker<ProfileObject: ControlsProfileObject>: View {
    let system: System
    let load: (System) -> ProfileObject?
    let update: (System, ProfileObject?) -> Void

    @EnvironmentObject private var settings: Settings
    @State private var profile: ProfileObject?

    var body: some View {
        ControlsProfilePicker(profile: $profile, defaultProfileLabel: "USING_DEFAULT_PROFILE", system: system, loading: settings.controlsProfilesLoading) {
            Text(system.string)
        }
        .onAppear {
            self.profile = self.load(system)
        }
        .onChange(of: profile) { newProfile in
            self.update(system, newProfile)
        }
    }
}
