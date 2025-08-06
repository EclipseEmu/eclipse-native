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
					Label("INPUT", systemImage: "dpad")
				}
				Picker(selection: $viewModel.mappings.directionals[target].style) {
					Label("DIRECTIONAL_STYLE_DPAD", systemImage: "dpad").tag(TouchMappings.Directional.Style.dpad)
					Label("DIRECTIONAL_STYLE_JOYSTICK", systemImage: "l.joystick").tag(TouchMappings.Directional.Style.joystick)
				} label: {
					Label("STYLE", systemImage: "paintpalette")
				}
			}

			Section {
				LabeledContent {
					Text(viewModel.mappings.directionals[target].deadzone, format: .number.precision(.fractionLength(2...2)))
						.font(.body.monospaced())
				} label: {
					Label("DEAD_ZONE", systemImage: "smallcircle.circle")
				}
				Slider(value: $viewModel.mappings.directionals[target].deadzone, in: 0.25...0.95, step: 0.05) {}
					.labelsHidden()
			} footer: {
				Text("DEAD_ZONE_EXPLAINER")
			}
		}
		.navigationTitle("EDIT_DIRECTIONAL")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				CancelButton("CANCEL", action: dismissAction.callAsFunction)
			}
		}
	}
}
#endif
