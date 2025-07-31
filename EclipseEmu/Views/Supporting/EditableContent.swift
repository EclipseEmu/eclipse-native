import SwiftUI

struct EditableContent<Label: View>: View {
	let action: () -> Void
	let label: () -> Label

	init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
		self.action = action
		self.label = label
	}

	var body: some View {
		LabeledContent(content: {
			Button("EDIT", action: action)
				.buttonStyle(.bordered)
				.buttonBorderShape(.capsule)
		}, label: label)
	}
}
