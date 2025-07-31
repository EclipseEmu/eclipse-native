#if canImport(UIKit)
import SwiftUI
import EclipseKit

extension ControlMappingDirection {
	var label: String {
		switch self {
		case .none: "None"
		case .fullPositiveY: "Up"
		case .halfPositiveY: "Half Up"
		case .fullNegativeY: "Down"
		case .halfNegativeY: "Half Down"
		case .fullPositiveX: "Right"
		case .halfPositiveX: "Half Right"
		case .fullNegativeX: "Left"
		case .halfNegativeX: "Half Left"
		}
	}
}

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
				ForEach(viewModel.mappings.buttons[target].input, id: \.rawValue) { input in
					let (text, image) = input.label(for: viewModel.namingConvention)
					Label(text, systemImage: image)
				}
				.onDelete(perform: removeInputs)

				Button {
					isAddInputPopoverOpen = true
				} label: {
					Label("Add Input", systemImage: "plus")
				}
				.sheet(isPresented: $isAddInputPopoverOpen) {
					NavigationStack {
						TouchEditorButtonAddInputView(inputs: $viewModel.mappings.buttons[target].input, system: viewModel.system)
					}
					.presentationDetents([.medium, .large])
				}
			}

			Section {
				Toggle(isOn: $viewModel.mappings.buttons[target].visible) {
					Label("Visible", systemImage: "eye")
				}
				Picker(selection: $viewModel.mappings.buttons[target].direction) {
					ForEach(ControlMappingDirection.allCases, id: \.rawValue) { direction in
						Text(direction.label).tag(direction)
					}
				} label: {
					Label("Direction", systemImage: "dpad")
				}
			} footer: {
				Text("The direction applies analog input to the button, which is useful if you're binding individual buttons to a directional input, like a thumbstick or directional pad.")
			}
		}
		.navigationTitle("Edit Button")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				CancelButton("Cancel", action: dismissAction.callAsFunction)
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
