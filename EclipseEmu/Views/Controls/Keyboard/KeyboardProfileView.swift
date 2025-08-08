import SwiftUI

struct KeyboardProfileView: View {
    @ObservedObject var profile: KeyboardProfileObject

    var body: some View {
        ControlsProfileLoader<InputSourceKeyboardDescriptor, _>(profile) { onChange, bindings in
            KeyboardEditorView(onChange: onChange, bindings: bindings, system: profile.system)
                .navigationTitle(profile.name ?? "PROFILE_UNNAMED")
        }
    }
}
