import SwiftUI

struct KeyboardEditorElementView: View {
    @ObservedObject var viewModel: KeyboardEditorViewModel
    var element: KeyboardEditorElement
    @Binding var editTarget: EditorTarget<Int>?
    
    init(_ element: KeyboardEditorElement, viewModel: KeyboardEditorViewModel, editTarget: Binding<EditorTarget<Int>?>) {
        self.element = element
        self.viewModel = viewModel
        self._editTarget = editTarget
    }
    
    var body: some View {
        EditableContent(action: edit) {
            let (text, image) = element.mapping.input.label(for: viewModel.namingConvention)
            Label {
                VStack(alignment: .leading) {
                    Text(element.keycode.displayName)
                    Self.keybindingButtonLabel(text, direction: element.mapping.direction)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } icon: {
                Image(systemName: image)
            }
        }
    }
    
    static func keybindingButtonLabel(_ text: String, direction: ControlMappingDirection) -> Text {
        if direction == .none {
            Text(text)
        } else {
            Text("\(text), \(direction.label)")
        }
    }
    
    func edit() {
        guard let index = viewModel.elements.firstIndex(where: { $0.keycode == element.keycode }) else {
            return
        }
        self.editTarget = .edit(index)
    }
}
