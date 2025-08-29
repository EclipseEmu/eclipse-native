#if canImport(UIKit)
import SwiftUI
import EclipseKit

struct TouchEditorDirectionalView: View {
	@Environment(\.dismiss) var dismissAction: DismissAction

	@ObservedObject private var viewModel: TouchEditorViewModel
	private let target: Int

	init(viewModel: TouchEditorViewModel, target: Int) {
		self.viewModel = viewModel
		self.target = target
	}

	var body: some View {
		Form {
			Section {
				Picker("INPUT", systemImage: "dpad", selection: $viewModel.mappings.directionals[target].input) {
					ForEach(CoreInput.directionalInputs(for: viewModel.system), id: \.rawValue) { input in
						let (text, image) = viewModel.mappings.directionals[target].input.label(for: viewModel.namingConvention)
						Label(text, systemImage: image).tag(input)
					}
				}
				Picker("STYLE", systemImage: "paintpalette", selection: $viewModel.mappings.directionals[target].style) {
					Label("DIRECTIONAL_STYLE_DPAD", systemImage: "dpad").tag(TouchMappings.Directional.Style.dpad)
					Label("DIRECTIONAL_STYLE_JOYSTICK", systemImage: "l.joystick").tag(TouchMappings.Directional.Style.joystick)
				}
			}

            DeadZoneEditorSectionView($viewModel.mappings.directionals[target].deadzone)
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
