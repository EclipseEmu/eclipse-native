import SwiftUI
import EclipseKit

struct ControlsSystemProfilesView<ProfileObject: ControlsProfileObject>: View {
    let load: (System) async throws -> ProfileObject?
    let update: (System, ProfileObject?) async throws -> Void
    
    var body: some View {
        ForEach(System.concreteCases, id: \.rawValue) { system in
            LazyControlsProfilePicker("USING_DEFAULT_PROFILE", system: system, load: load, update: update) {
                Text(system.string)
            }
        }
    }
}
