#if canImport(UIKit)
import SwiftUI
import EclipseKit

struct TouchEditorButtonAddInputView: View {
	@Binding var inputs: CoreInput
	let system: System

	@Environment(\.dismiss) private var dismissAction: DismissAction

	var body: some View {
		List {
			ForEach(inputs.symmetricDifference(CoreInput.inputs(for: system)), id: \.rawValue) { input in
				Button {
					inputs.insert(input)
				} label: {
					let (text, image) = input.label(for: system.controlNamingConvention)
					Label(text, systemImage: image)
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				CancelButton("Done", action: dismissAction.callAsFunction)
			}
		}
		.navigationTitle("Add Input")
#if !os(macOS)
		.navigationBarTitleDisplayMode(.inline)
#endif
	}
}

#Preview {
	TouchEditorButtonAddInputView(inputs: .constant([.dpad, .faceButtonDown]), system: .gba)
}
#endif
