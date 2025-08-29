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
    
    init(
        title: String,
        systemImage: String,
        rect: Binding<TouchMappings.RelativeRect>,
        focusTarget: FocusState<TouchEditorVariantView.Field?>.Binding,
        yOffsetID: TouchEditorVariantView.Field,
        xOffsetID: TouchEditorVariantView.Field,
        sizeID: TouchEditorVariantView.Field
    ) {
        self.title = title
        self.systemImage = systemImage
        self._rect = rect
        self._focusTarget = focusTarget
        self.yOffsetID = yOffsetID
        self.xOffsetID = xOffsetID
        self.sizeID = sizeID
    }
    
	var body: some View {
		LabeledContent {
			ToggleButton("EDIT", value: $isShown)
				.buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .popover(isPresented: $isShown) {
                    TouchEditorRectElementPopoverView(title: title, rect: $rect, focusTarget: $focusTarget, yOffsetID: yOffsetID, xOffsetID: xOffsetID, sizeID: sizeID)
                }
		} label: {
			Label(title, systemImage: systemImage)
		}
	}
}

private struct TouchEditorRectElementPopoverView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    private let title: String
    @Binding private var rect: TouchMappings.RelativeRect
    @FocusState.Binding private var focusTarget: TouchEditorVariantView.Field?
    private var yOffsetID: TouchEditorVariantView.Field
    private var xOffsetID: TouchEditorVariantView.Field
    private var sizeID: TouchEditorVariantView.Field
    
    init(
        title: String,
        rect: Binding<TouchMappings.RelativeRect>,
        focusTarget: FocusState<TouchEditorVariantView.Field?>.Binding,
        yOffsetID: TouchEditorVariantView.Field,
        xOffsetID: TouchEditorVariantView.Field,
        sizeID: TouchEditorVariantView.Field
    ) {
        self.title = title
        self._rect = rect
        self._focusTarget = focusTarget
        self.yOffsetID = yOffsetID
        self.xOffsetID = xOffsetID
        self.sizeID = sizeID
    }
    
    var body: some View {
        TouchEditorRectFormView(rect: $rect, focusTarget: $focusTarget, yOffsetID: yOffsetID, xOffsetID: xOffsetID, sizeID: sizeID)
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
    }
}

/// A thin wrapper around ``TouchEditorRectElementView``, which offers equatability.
struct TouchEditorElementView: @MainActor Equatable, View {
	@ObservedObject private var viewModel: TouchEditorViewModel
	private let variant: Int
	private let element: TouchMappings.Element
	@FocusState.Binding private var focusTarget: TouchEditorVariantView.Field?
    
    init(
        viewModel: TouchEditorViewModel,
        variant: Int,
        element: TouchMappings.Element,
        focusTarget: FocusState<TouchEditorVariantView.Field?>.Binding
    ) {
        self.viewModel = viewModel
        self.variant = variant
        self.element = element
        self._focusTarget = focusTarget
    }
    
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
	@Binding private var rect: TouchMappings.RelativeRect
	@FocusState.Binding private var focusTarget: TouchEditorVariantView.Field?
	private let yOffsetID: TouchEditorVariantView.Field
	private let xOffsetID: TouchEditorVariantView.Field
	private let sizeID: TouchEditorVariantView.Field
    
    init(
        rect: Binding<TouchMappings.RelativeRect>,
        focusTarget: FocusState<TouchEditorVariantView.Field?>.Binding,
        yOffsetID: TouchEditorVariantView.Field,
        xOffsetID: TouchEditorVariantView.Field,
        sizeID: TouchEditorVariantView.Field
    ) {
        self._rect = rect
        self._focusTarget = focusTarget
        self.yOffsetID = yOffsetID
        self.xOffsetID = xOffsetID
        self.sizeID = sizeID
    }
    
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

			TouchEditorPositionField("X_OFFSET", value: $rect.xOffset, focusTarget: $focusTarget, id: xOffsetID)
			TouchEditorPositionField("Y_OFFSET", value: $rect.yOffset, focusTarget: $focusTarget, id: yOffsetID)
			TouchEditorPositionField("SIZE", value: $rect.size, focusTarget: $focusTarget, id: sizeID)
		}
	}
}
#endif
