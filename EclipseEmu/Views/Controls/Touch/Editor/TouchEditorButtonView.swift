#if canImport(UIKit)
import SwiftUI
import EclipseKit

struct TouchEditorButtonView: View {
	@Environment(\.dismiss) var dismissAction: DismissAction

	@ObservedObject var viewModel: TouchEditorViewModel
	let target: Int

	@State private var isAddInputPopoverOpen: Bool = false

	init(viewModel: TouchEditorViewModel, target: Int) {
		self.viewModel = viewModel
		self.target = target
	}

	var body: some View {
		Form {
			Section {
                InputPickerView(inputs: $viewModel.mappings.buttons[target].input, availableInputs: viewModel.system.inputs, namingConvention: viewModel.namingConvention)
                
				Picker("DIRECTION", systemImage: "dpad", selection: $viewModel.mappings.buttons[target].direction) {
					ForEach(ControlMappingDirection.allCases, id: \.rawValue) { direction in
						Text(direction.label).tag(direction)
					}
				}
			} footer: {
				Text("CONTROLS_DIRECTION_EXPLAINER")
			}
            
            Section {
                Toggle("VISIBLE", systemImage: "eye", isOn: $viewModel.mappings.buttons[target].visible)
            }
		}
		.navigationTitle("EDIT_BUTTON")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				CancelButton("CANCEL", action: dismissAction.callAsFunction)
			}
		}
	}

	func removeInputs(_ indices: IndexSet) {
		var remove: CoreInput = []
		for i in indices {
			let input = viewModel.mappings.buttons[target].input[i]
			remove.insert(input)
		}
		self.viewModel.mappings.buttons[target].input.remove(remove)
	}
}
#endif
