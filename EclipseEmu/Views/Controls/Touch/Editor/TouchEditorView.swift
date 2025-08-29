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
	@Environment(\.dismiss) private var dismiss: DismissAction

    @StateObject private var viewModel: TouchEditorViewModel
	@State private var buttonEditTarget: TouchEditorViewModel.EditTarget?
	@State private var directionalEditTarget: TouchEditorViewModel.EditTarget?
    
    init(
        onChange: @escaping ControlsProfileUpdateCallback<InputSourceTouchDescriptor>,
        bindings: TouchMappings,
        system: System
    ) {
        self._viewModel = .init(wrappedValue: { .init(mappings: bindings, system: system, onChange: onChange) }())
    }
    
	var body: some View {
		Form {
			Section("VARIANTS") {
				ForEach(viewModel.mappings.variants) { variant in
					if let index = viewModel.index(of: variant) {
                        let label = variant.sizing.label
                        NavigationLink(label.0, systemImage: label.systemImage, to: .touchEditorVariant(index, viewModel))
					}
				}
				.onDelete(perform: deleteVariants)
			}

			Section("DIRECTIONALS") {
				ForEach(viewModel.mappings.directionals) { directional in
                    let label = viewModel.label(for: directional)
                    EditableContent(verbatim: label.0, systemImage: label.systemImage) {
                        directionalEditTarget = viewModel.index(of: directional).map(TouchEditorViewModel.EditTarget.init)
                    }
				}
				.onDelete(perform: deleteDirectionals)
			}

			Section("BUTTONS") {
				ForEach(viewModel.mappings.buttons) { button in
                    let label = viewModel.label(for: button)
                    EditableContent(verbatim: label.0, systemImage: label.systemImage) {
                        buttonEditTarget = viewModel.index(of: button).map(TouchEditorViewModel.EditTarget.init)
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
				Menu("ADD_ELEMENT", systemImage: "plus") {
					Button("ADD_BUTTON", systemImage: "a.circle", action: addButton)
					Button("ADD_DIRECTIONAL", systemImage: "dpad", action: addDirectional)
					Divider()
					addVariantMenuContents
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
	private var addVariantMenuContents: some View {
		Menu("ADD_VARIANT", systemImage: "iphone.sizes") {
			ForEach(TouchMappings.VariantSizing.allCases, id: \.rawValue) { variant in
                let (text, image) = variant.label
				Button(text, systemImage: image) {
					self.createLayout(sizing: variant)
				}
				.disabled(viewModel.mappings.variants.contains(where: { $0.sizing == variant }))
			}
		}
		.disabled(viewModel.mappings.variants.count == TouchMappings.VariantSizing.allCases.count)
	}

	private func addButton() {
		var button = TouchMappings.Button.init(id: 0, input: [])
		let index = viewModel.mappings.insert(&button)
		buttonEditTarget = .init(id: index)
	}

	private func addDirectional() {
		var directional = TouchMappings.Directional.init(id: 0, input: [], deadzone: 0.5, style: .dpad)
		let index = viewModel.mappings.insert(&directional)
		directionalEditTarget = .init(id: index)
	}

	private func createLayout(sizing: TouchMappings.VariantSizing) {
		viewModel.mappings.insertVariant(for: sizing)
	}

	private func deleteVariants(_ indices: IndexSet) {
		viewModel.mappings.variants.remove(atOffsets: indices)
	}

	private func deleteButtons(_ indices: IndexSet) {
		viewModel.mappings.removeButtons(indices)
	}

	private func deleteDirectionals(_ indices: IndexSet) {
		viewModel.mappings.removeDirectionals(indices)
	}
}
#endif
