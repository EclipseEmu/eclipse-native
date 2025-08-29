#if canImport(UIKit)
import SwiftUI

struct TouchEditorPositionField<Field: Hashable>: View {
	private let title: LocalizedStringKey
	@Binding private var value: Float
	@FocusState.Binding private var focusTarget: Field?
    private let id: Field

	init(_ title: LocalizedStringKey, value: Binding<Float>, focusTarget: FocusState<Field?>.Binding, id: Field) {
		self.title = title
		self._value = value
		self._focusTarget = focusTarget
		self.id = id
	}

	var body: some View {
		LabeledContent(title) {
			TextField(title, value: $value, format: .number)
				.focused($focusTarget, equals: id)
				.keyboardType(.decimalPad)
		}
	}
}
#endif
