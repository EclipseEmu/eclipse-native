#if canImport(UIKit)
import SwiftUI

struct TouchProfileView: View {
	@ObservedObject var object: TouchProfileObject

	var body: some View {
		ControlsProfileLoader<InputSourceTouchDescriptor, _>(object) { onChange, bindings in
            TouchEditorView(onChange: onChange, bindings: bindings, system: object.system)
		}
	}
}
#endif
