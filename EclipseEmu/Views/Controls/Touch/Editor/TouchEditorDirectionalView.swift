#if canImport(UIKit)
import SwiftUI
import EclipseKit

struct TouchEditorDirectionalView: View {
	@Environment(\.dismiss) var dismissAction: DismissAction

	@ObservedObject var viewModel: TouchEditorViewModel
	let target: Int

	init(viewModel: TouchEditorViewModel, target: Int) {
		self.viewModel = viewModel
		self.target = target
	}

	var body: some View {
		Form {
			Section {
				Picker(selection: $viewModel.mappings.directionals[target].input) {
					ForEach(CoreInput.directionalInputs(for: viewModel.system), id: \.rawValue) { input in
						let (text, image) = viewModel.mappings.directionals[target].input.label(for: viewModel.namingConvention)
						Label(text, systemImage: image).tag(input)
					}
				} label: {
					Label("Input", systemImage: "dpad")
				}
				Picker(selection: $viewModel.mappings.directionals[target].style) {
					Label("D-Pad", systemImage: "dpad").tag(TouchMappings.Directional.Style.dpad)
					Label("Joystick", systemImage: "l.joystick").tag(TouchMappings.Directional.Style.joystick)
				} label: {
					Label("Style", systemImage: "paintpalette")
				}
			}

			Section {
				LabeledContent {
					Text(viewModel.mappings.directionals[target].deadzone, format: .number.precision(.fractionLength(2...2)))
						.font(.body.monospaced())
				} label: {
					Label("Dead Zone", systemImage: "smallcircle.circle")
				}
				Slider(value: $viewModel.mappings.directionals[target].deadzone, in: 0.25...0.95, step: 0.05) {}
					.labelsHidden()
			} footer: {
				Text("The dead zone is the radius that inputs are ignored within.")
			}
		}
		.navigationTitle("Edit Directional")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				CancelButton("Cancel", action: dismissAction.callAsFunction)
			}
		}
	}
}
#endif
