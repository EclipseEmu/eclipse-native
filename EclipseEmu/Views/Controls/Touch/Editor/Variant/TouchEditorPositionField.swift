#if canImport(UIKit)
import SwiftUI

struct TouchEditorPositionField<Field: Hashable>: View {
	var title: LocalizedStringKey
	@Binding var value: Float
	let alignment: NSTextAlignment
	let id: Field

	@FocusState.Binding var focusTarget: Field?

	init(_ title: LocalizedStringKey, value: Binding<Float>, alignment: NSTextAlignment, focusTarget: FocusState<Field?>.Binding, id: Field) {
		self.title = title
		self._value = value
		self.alignment = alignment
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
