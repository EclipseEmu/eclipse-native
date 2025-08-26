import SwiftUI

struct ControllerProfileView: View {
    @ObservedObject var profile: ControllerProfileObject

    var body: some View {
        ControlsProfileLoader<InputSourceControllerDescriptor, _>(profile) { onChange, bindings in
            ControllerEditorView(onChange: onChange, bindings: bindings, system: profile.system)
                .navigationTitle(profile.name ?? "PROFILE_UNNAMED")
        }
    }
}
