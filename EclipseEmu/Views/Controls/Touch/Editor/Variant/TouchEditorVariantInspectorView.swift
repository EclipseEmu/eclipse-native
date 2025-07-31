#if canImport(UIKit)
import SwiftUI

private struct AvailableControl: Identifiable {
	let id: Int
	let text: String
	let image: String
}

struct TouchEditorVariantInspectorView: View {
	@ObservedObject var viewModel: TouchEditorViewModel
	let target: Int

	@FocusState.Binding var focusTarget: TouchEditorVariantView.Field?

	@State private var proxy: ScrollViewProxy?
	@State private var availableButtons: [AvailableControl] = []
	@State private var availableDirectionals: [AvailableControl] = []

	var body: some View {
		Form {
			Section("Screen Offset") {
				TouchEditorPositionField("X Offset", value: $viewModel.mappings.variants[target].screenOffset.x, alignment: .right, focusTarget: $focusTarget, id: .screenOffsetX)
				TouchEditorPositionField("Y Offset", value: $viewModel.mappings.variants[target].screenOffset.y, alignment: .right, focusTarget: $focusTarget, id: .screenOffsetY)
			}

			Section("Elements") {
				TouchEditorRectElementView(
					title: "Menu",
					systemImage: "house.circle",
					rect: $viewModel.mappings.variants[target].menu,
					focusTarget: $focusTarget,
					yOffsetID: .menuOffsetY,
					xOffsetID: .menuOffsetX,
					sizeID: .menuSize
				)
				ForEach(viewModel.mappings.variants[target].elements) { el in
					EquatableView(content: TouchEditorElementView(viewModel: viewModel, variant: target, element: el, focusTarget: $focusTarget))
				}
				.onDelete(perform: deleteElements)
			}
		}
		.toolbar {
			ToolbarItem {
				EditButton()
			}
			ToolbarItem {
				Menu {
					ForEach(availableDirectionals) { control in
						Button {
							insertElement(for: .directional(control.id))
						} label: {
							Label(control.text, systemImage: control.image)
						}
					}
					if !availableButtons.isEmpty && !availableDirectionals.isEmpty {
						Divider()
					}
					ForEach(availableButtons) { control in
						Button {
							insertElement(for: .button(control.id))
						} label: {
							Label(control.text, systemImage: control.image)
						}
					}
				} label: {
					Label("Add Element", systemImage: "plus")
				}
				.disabled(availableButtons.isEmpty && availableDirectionals.isEmpty)
				.onAppear(perform: loadAvailableElements)
			}
		}
	}

	func insertElement(for control: TouchMappings.ControlIndex) {
		viewModel.mappings.variants[target].insert(control: control)
		loadAvailableElements()
	}

	func deleteElements(_ indices: IndexSet) {
		viewModel.mappings.variants[target].elements.remove(atOffsets: indices)
		loadAvailableElements()
	}

	func loadAvailableElements() {
		let availableControls = viewModel.mappings.availableControls(for: target)
		let namingConvention = viewModel.namingConvention
		self.availableButtons = availableControls.buttons.map { index in
			let label = viewModel.mappings.buttons[index].input.label(for: namingConvention)
			return AvailableControl(id: index, text: label.0, image: label.systemImage)
		}
		self.availableDirectionals = availableControls.directionals.map { index in
			let label = viewModel.mappings.directionals[index].input.label(for: namingConvention)
			return AvailableControl(id: index, text: label.0, image: label.systemImage)
		}
	}
}
#endif
