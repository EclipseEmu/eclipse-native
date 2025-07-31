import SwiftUI

/// A button that toggles a boolean.
/// This is to be used in scenarios where you want an actual `SwiftUI.Button`, but only need to toggle a single value.
/// While you can use a `SwiftUI.Toggle` and use set its style to `.button`,
/// this is missing important button semantics, i.e. role styling.
struct ToggleButton<Label: View>: View {
    let role: ButtonRole?
    @Binding var value: Bool
    let label: () -> Label

    init(role: ButtonRole? = nil, value: Binding<Bool>, label: @escaping () -> Label) {
        self.role = role
        self._value = value
        self.label = label
    }

    var body: Button<Label> {
        Button(role: role, action: action, label: label)
    }

    private func action() {
        self.value.toggle()
    }
}

extension ToggleButton where Label == Text {
	init(_ label: some StringProtocol, role: ButtonRole? = nil, value: Binding<Bool>) {
		self.role = role
		self._value = value
		self.label = { Text(label) }
	}
}
