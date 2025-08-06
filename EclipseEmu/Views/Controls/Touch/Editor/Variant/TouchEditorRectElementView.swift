#if canImport(UIKit)
import SwiftUI

struct TouchEditorRectElementView: View {
	let title: String
	let systemImage: String
	@Binding var rect: TouchMappings.RelativeRect
	@State private var isShown: Bool = false

	@FocusState.Binding var focusTarget: TouchEditorVariantView.Field?
	var yOffsetID: TouchEditorVariantView.Field
	var xOffsetID: TouchEditorVariantView.Field
	var sizeID: TouchEditorVariantView.Field

	var body: some View {
		LabeledContent {
			ToggleButton("EDIT", value: $isShown)
				.buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .popover(isPresented: $isShown) {
                    popoverContent
                }
		} label: {
			Label(title, systemImage: systemImage)
		}
	}

	@ViewBuilder
    var popoverContent: some View {
		TouchEditorRectFormView(rect: $rect, focusTarget: $focusTarget, yOffsetID: yOffsetID, xOffsetID: xOffsetID, sizeID: sizeID)
			.modify { view in
				if #available(iOS 16.4, *) {
					view
						.presentationCompactAdaptation(.popover)
						.frame(minWidth: 200, idealWidth: 300, minHeight: 200)
						.padding()
						.formStyle(.columns)
						.scrollContentBackground(.hidden)
						.modify {
							if #available(iOS 18.0, *) {
								$0.presentationSizing(.fitted)
							} else {
								$0
							}
						}
				} else {
					NavigationStack {
						view
							.navigationTitle(title)
							.navigationBarTitleDisplayMode(.inline)
							.toolbar {
								ToolbarItem(placement: .cancellationAction) {
									DismissButton("DONE")
								}
							}
					}
					.presentationDetents([.medium])
				}
			}
	}
}

/// A thin wrapper around ``TouchEditorRectElementView``, which offers equatability.
struct TouchEditorElementView: @MainActor Equatable, View {
	@ObservedObject var viewModel: TouchEditorViewModel
	let variant: Int
	let element: TouchMappings.Element

	@FocusState.Binding var focusTarget: TouchEditorVariantView.Field?

	static func == (lhs: TouchEditorElementView, rhs: TouchEditorElementView) -> Bool {
		lhs.element.control == rhs.element.control
	}

	var body: some View {
		let label = viewModel.label(for: element.control)
		if let offset = viewModel.mappings.variants[variant].elements.firstIndex(of: element) {
			TouchEditorRectElementView(
				title: label.0,
				systemImage: label.systemImage,
				rect: $viewModel.mappings.variants[variant].elements[offset].rect,
				focusTarget: $focusTarget,
				yOffsetID: .elementOffsetY(offset),
				xOffsetID: .elementOffsetX(offset),
				sizeID: .elementSize(offset)
			)
		}
	}
}

struct TouchEditorRectFormView: View {
	@Binding var rect: TouchMappings.RelativeRect
	@FocusState.Binding var focusTarget: TouchEditorVariantView.Field?
	var yOffsetID: TouchEditorVariantView.Field
	var xOffsetID: TouchEditorVariantView.Field
	var sizeID: TouchEditorVariantView.Field

	var body: some View {
		Form {
			Picker("X_ORIGIN", selection: $rect.xOrigin) {
				Text("LEFT").tag(TouchMappings.RelativeRect.XOrigin.left)
				Text("CENTER").tag(TouchMappings.RelativeRect.XOrigin.center)
				Text("RIGHT").tag(TouchMappings.RelativeRect.XOrigin.right)
			}

			Picker("Y_ORIGIN", selection: $rect.yOrigin) {
				Text("TOP").tag(TouchMappings.RelativeRect.YOrigin.top)
				Text("CENTER").tag(TouchMappings.RelativeRect.YOrigin.center)
				Text("BOTTOM").tag(TouchMappings.RelativeRect.YOrigin.bottom)
			}

			TouchEditorPositionField("X_OFFSET", value: $rect.xOffset, alignment: .natural, focusTarget: $focusTarget, id: xOffsetID)
			TouchEditorPositionField("Y_OFFSET", value: $rect.yOffset, alignment: .natural, focusTarget: $focusTarget, id: yOffsetID)
			TouchEditorPositionField("SIZE", value: $rect.size, alignment: .natural, focusTarget: $focusTarget, id: sizeID)
		}
	}
}
#endif
