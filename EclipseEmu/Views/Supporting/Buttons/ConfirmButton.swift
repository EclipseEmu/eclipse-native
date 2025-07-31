import SwiftUI

@available(iOS, deprecated: 26.0, renamed: "Button", message: "This is a wrapper around Button that supports the new confirm styling.")
struct ConfirmButton<Content: View>: View {
	let action: () -> Void
	let label: () -> Content

	init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Content) {
		self.action = action
		self.label = label
	}

	var body: some View {
		if #available(iOS 26.0, macOS 26.0, *) {
			Button(role: .confirm, action: action)
		} else {
			Button(action: action, label: label)
		}
	}
}

extension ConfirmButton where Content == Text {
	init(_ label: LocalizedStringKey, action: @escaping () -> Void) {
		self.label = { Text(label) }
		self.action = action
	}
}
