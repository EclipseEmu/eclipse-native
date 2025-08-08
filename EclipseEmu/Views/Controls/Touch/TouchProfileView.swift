#if canImport(UIKit)
import SwiftUI

struct TouchProfileView: View {
	@ObservedObject var profile: TouchProfileObject

	var body: some View {
		ControlsProfileLoader<InputSourceTouchDescriptor, _>(profile) { onChange, bindings in
            TouchEditorView(onChange: onChange, bindings: bindings, system: profile.system)
                .navigationTitle(profile.name ?? "PROFILE_UNNAMED")
		}
	}
}
#endif
