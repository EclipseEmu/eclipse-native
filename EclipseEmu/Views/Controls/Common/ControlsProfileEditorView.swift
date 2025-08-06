import SwiftUI
import EclipseKit

final class ControlProfileEditorControl<Binding>: ObservableObject, Equatable, Hashable {
    let input: CoreInput
    @Published var binding: Binding?

    init(input: CoreInput, binding: Binding? = nil) {
        self.input = input
        self.binding = binding
    }

    static func ==(lhs: ControlProfileEditorControl<Binding>, rhs: ControlProfileEditorControl<Binding>) -> Bool {
        lhs.input == rhs.input
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(input.rawValue)
    }
}

struct ControlProfileEditorContolCollection<Binding>: Identifiable {
    let id = UUID()
    var items: [ControlProfileEditorControl<Binding>]
}

struct ControlsProfileEditorView<ControlBinding, PickerContent: View>: View {
    let system: System
    let inputs: [ControlProfileEditorContolCollection<ControlBinding>]
    let picker: (ControlProfileEditorControl<ControlBinding>) -> PickerContent

    var body: some View {
        Form {
            ForEach(inputs) { section in
                Section {
                    ForEach(section.items, id: \.input.rawValue) { binding in
                        picker(binding).hidden(if: !system.inputs.contains(binding.input))
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
