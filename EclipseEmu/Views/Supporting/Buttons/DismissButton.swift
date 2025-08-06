import SwiftUI

// FIXME: This doesn't seem to work on macOS

struct DismissButton<Content: View>: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    let label: () -> Content

    init(@ViewBuilder label: @escaping () -> Content) {
        self.label = label
    }

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Button(role: .cancel, action: dismiss.callAsFunction)
        } else {
            Button(role: .cancel, action: dismiss.callAsFunction, label: label)
        }
    }
}

extension DismissButton where Content == Text {
	init(_ label: LocalizedStringKey) {
		self.label = { Text(label) }
	}
}
