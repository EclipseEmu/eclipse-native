#if canImport(UIKit)
import SwiftUI
import EclipseKit

extension TouchMappings.VariantSizing {
	var label: (LocalizedStringKey, systemImage: String) {
		switch self {
		case .any: 				("ANY", systemImage: "square.dashed")
		case .portraitCompact: 	("VARIANT_IPHONE_PORTRAIT", systemImage: "iphone")
		case .landscapeCompact: ("VARIANT_IPHONE_LANDSCAPE", systemImage: "iphone.landscape")
		case .portraitRegular: 	("VARIANT_IPAD_PORTRAIT", systemImage: "ipad")
		case .landscapeRegular: ("VARIANT_IPAD_LANDSCAPE", systemImage: "ipad.landscape")
		}
	}
}

struct TouchEditorView: View {
	@StateObject var viewModel: TouchEditorViewModel
	@Environment(\.dismiss) var dismiss: DismissAction

	@State var buttonEditTarget: TouchEditorViewModel.EditTarget?
	@State var directionalEditTarget: TouchEditorViewModel.EditTarget?
    
    init(onChange: @escaping ControlsProfileUpdateCallback<InputSourceTouchDescriptor>, bindings: TouchMappings, system: System) {
        self._viewModel = .init(wrappedValue: { .init(mappings: bindings, system: system, onChange: onChange) }())
    }
    
	var body: some View {
		Form {
			Section("VARIANTS") {
				ForEach(viewModel.mappings.variants) { variant in
					if let index = viewModel.index(of: variant) {
						NavigationLink(value: Destination.touchEditorVariant(index, viewModel)) {
							let label = variant.sizing.label
							Label(label.0, systemImage: label.systemImage)
						}
					}
				}
				.onDelete(perform: deleteVariants)
			}

			Section("DIRECTIONALS") {
				ForEach(viewModel.mappings.directionals) { directional in
                    EditableContent {
                        directionalEditTarget = viewModel.index(of: directional).map(TouchEditorViewModel.EditTarget.init)
                    } label: {
                        let label = viewModel.label(for: directional)
                        Label(label.0, systemImage: label.systemImage)
                    }
				}
				.onDelete(perform: deleteDirectionals)
			}

			Section("BUTTONS") {
				ForEach(viewModel.mappings.buttons) { button in
                    EditableContent {
                        buttonEditTarget = viewModel.index(of: button).map(TouchEditorViewModel.EditTarget.init)
                    } label: {
						let label = viewModel.label(for: button)
						Label(label.0, systemImage: label.systemImage)
					}
				}
				.onDelete(perform: deleteButtons)
			}
		}
		.toolbar {
			ToolbarItem {
				EditButton()
			}
			ToolbarItem {
				Menu {
					Button(action: addButton) {
						Label("ADD_BUTTON", systemImage: "a.circle")
					}
					Button(action: addDirectional) {
						Label("ADD_DIRECTIONAL", systemImage: "dpad")
					}
					Divider()
					addVariantMenuContents
				} label: {
					Label("ADD_ELEMENT", systemImage: "plus")
				}
			}
		}
		.sheet(item: $buttonEditTarget) { editTarget in
            FormSheetView {
				TouchEditorButtonView(viewModel: viewModel, target: editTarget.id)
			}
		}
		.sheet(item: $directionalEditTarget) { editTarget in
            FormSheetView {
				TouchEditorDirectionalView(viewModel: viewModel, target: editTarget.id)
			}
		}
	}

	@ViewBuilder
	var addVariantMenuContents: some View {
		Menu {
			ForEach(TouchMappings.VariantSizing.allCases, id: \.rawValue) { variant in
				Button {
					self.createLayout(sizing: variant)
				} label: {
					let (text, image) = variant.label
					Label(text, systemImage: image).tag(variant)
				}
				.disabled(viewModel.mappings.variants.contains(where: { $0.sizing == variant }))
			}
		} label: {
			Label("ADD_VARIANT", systemImage: "iphone.sizes")
		}
		.disabled(viewModel.mappings.variants.count == TouchMappings.VariantSizing.allCases.count)
	}

	func addButton() {
		var button = TouchMappings.Button.init(id: 0, input: [])
		let index = viewModel.mappings.insert(&button)
		buttonEditTarget = .init(id: index)
	}

	func addDirectional() {
		var directional = TouchMappings.Directional.init(id: 0, input: [], deadzone: 0.5, style: .dpad)
		let index = viewModel.mappings.insert(&directional)
		directionalEditTarget = .init(id: index)
	}

	func createLayout(sizing: TouchMappings.VariantSizing) {
		viewModel.mappings.insertVariant(for: sizing)
	}

	@inlinable
	func deleteVariants(_ indices: IndexSet) {
		viewModel.mappings.variants.remove(atOffsets: indices)
	}

	@inlinable
	func deleteButtons(_ indices: IndexSet) {
		viewModel.mappings.removeButtons(indices)
	}

	@inlinable
	func deleteDirectionals(_ indices: IndexSet) {
		viewModel.mappings.removeDirectionals(indices)
	}
}
#endif
