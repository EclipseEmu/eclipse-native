#if canImport(UIKit)
import SwiftUI

struct TouchEditorVariantView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @ObservedObject private var viewModel: TouchEditorViewModel
	private let target: Int
	@State private var isInspectorShown = true
	@FocusState private var focusTarget: Field?
    
    init(viewModel: TouchEditorViewModel, target: Int) {
        self.viewModel = viewModel
        self.target = target
    }

	enum Field: Hashable {
		case screenOffsetX
		case screenOffsetY

		case menuOffsetX
		case menuOffsetY
		case menuSize

		case elementOffsetX(Int)
		case elementOffsetY(Int)
		case elementSize(Int)

		var isFlippable: Bool {
			switch self {
			case .elementOffsetX, .elementOffsetY, .menuOffsetX, .menuOffsetY, .screenOffsetX, .screenOffsetY: true
			default: false
			}
		}
	}

	var body: some View {
		content
			.toolbar {
				ToolbarItemGroup(placement: .keyboard) {
                    Button("TOGGLE_NEGATIVE", systemImage: "plus.forwardslash.minus", action: toggleNegative)
                        .disabled(focusTarget?.isFlippable != true)
					Spacer()
                    Button("HIDE_KEYBOARD", systemImage: "keyboard.chevron.compact.down", action: hideKeyboard)
				}
			}
	}

	@ViewBuilder
	private var content: some View {
		let isWide = horizontalSizeClass == .regular || verticalSizeClass == .compact
		let layout = isWide ? AnyLayout(HStackLayout(spacing: 0.0)) : AnyLayout(VStackLayout(spacing: 0.0))

		layout {
			preview
			Rectangle().frame(width: isWide ? 1 : nil, height: isWide ? nil : 1).ignoresSafeArea().foregroundStyle(Color(uiColor: .separator))
			form
				.safeAreaInset(edge: .top) {
					Rectangle().frame(height: isWide ? 0.0 : 16.0).foregroundStyle(Color.clear)
				}
				.frame(maxWidth: isWide ? 375.0 : nil)
		}
	}

	@ViewBuilder
	private var preview: some View {
		TouchEditorVariantPreviewView(viewModel: viewModel, variant: $viewModel.mappings.variants[target])
			.padding(32)
			.background(Color(uiColor: .systemGray4))
	}
    
    @ViewBuilder
    private var form: some View {
        TouchEditorVariantInspectorView(viewModel: viewModel, target: target, focusTarget: $focusTarget)
    }
    
    private func toggleNegative() {
        switch focusTarget {
        case .screenOffsetX:
            viewModel.mappings.variants[target].screenOffset.x *= -1
        case .screenOffsetY:
            viewModel.mappings.variants[target].screenOffset.y *= -1
        case .menuOffsetX:
            viewModel.mappings.variants[target].menu.xOffset *= -1
        case .menuOffsetY:
            viewModel.mappings.variants[target].menu.yOffset *= -1
        case .elementOffsetX(let index):
            viewModel.mappings.variants[target].elements[index].rect.xOffset *= -1
        case .elementOffsetY(let index):
            viewModel.mappings.variants[target].elements[index].rect.yOffset *= -1
        case .elementSize, .menuSize, nil: break
        }
    }
    
    private func hideKeyboard() {
        focusTarget = nil
    }
}
#endif
