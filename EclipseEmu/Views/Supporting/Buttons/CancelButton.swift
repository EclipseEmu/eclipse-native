import SwiftUI

@available(iOS, deprecated: 26.0, renamed: "Button", message: "This is a wrapper around Button that supports the new cancel styling.")
struct CancelButton<Content: View>: View {
	let action: () -> Void
	let label: () -> Content

	init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Content) {
		self.action = action
		self.label = label
	}
    
	var body: some View {
		if #available(iOS 26.0, macOS 26.0, *) {
			Button(role: .cancel, action: action)
		} else {
			Button(role: .cancel, action: action, label: label)
		}
	}
}

extension CancelButton where Content == Text {
    init(_ label: some StringProtocol, action: @escaping () -> Void) {
        self.label = { Text(label) }
        self.action = action
    }
    
    init(action: @escaping () -> Void) {
        self.action = action
        self.label = { Text("CANCEL") }
    }
}
