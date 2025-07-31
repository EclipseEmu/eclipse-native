import SwiftUI
import EclipseKit
import GameController

struct ControllerProfileInputView: View {
    private let input: CoreInput
	private let namingConvention: ControlNamingConvention

    @State private var value: String = ""

	init(input: CoreInput, namingConvention: ControlNamingConvention) {
        self.input = input
		self.namingConvention = namingConvention
    }

    var body: some View {
        Picker(selection: $value) {
            Text("CONTROL_UNBOUND").tag("")
        } label: {
			let label = input.label(for: namingConvention)
			Label(label.0, systemImage: label.systemImage)
        }
    }
}

struct ControllerProfileInputPickerSheetView: View {
    var body: some View {

    }
}

#Preview {
    Form {
		ControllerProfileInputView(input: .dpad, namingConvention: .nintendo)
    }
}
