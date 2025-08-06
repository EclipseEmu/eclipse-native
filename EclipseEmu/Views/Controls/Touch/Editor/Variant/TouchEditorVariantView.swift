#if canImport(UIKit)
import SwiftUI

struct TouchEditorVariantView: View {
	@ObservedObject var viewModel: TouchEditorViewModel
	let target: Int

	@Environment(\.dismiss) var dismiss: DismissAction

	@State private var isInspectorShown = true
	@FocusState private var focusTarget: Field?

	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@Environment(\.verticalSizeClass) var verticalSizeClass

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
					Button {
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
					} label: {
						Label("TOGGLE_NEGATIVE", systemImage: "plus.forwardslash.minus")
					}
					.disabled(focusTarget?.isFlippable != true)

					Spacer()

					Button {
						focusTarget = nil
					} label: {
						Label("HIDE_KEYBOARD", systemImage: "keyboard.chevron.compact.down")
					}
				}
			}
	}

	@ViewBuilder
	var content: some View {
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
	var preview: some View {
		TouchEditorVariantPreviewView(viewModel: viewModel, variant: $viewModel.mappings.variants[target])
			.padding(32)
			.background(Color(uiColor: .systemGray4))
	}

	@ViewBuilder
	var form: some View {
		TouchEditorVariantInspectorView(viewModel: viewModel, target: target, focusTarget: $focusTarget)
	}
}
#endif
