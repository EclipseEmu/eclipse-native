import SwiftUI
import EclipseKit

final class ControlProfileEditorControl<Binding>: ObservableObject, Equatable, Hashable {
    let input: GameInput
    @Published var binding: Binding?

    init(input: GameInput, binding: Binding? = nil) {
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
    @Binding var name: String
    @Binding var system: GameSystem
    let inputs: [ControlProfileEditorContolCollection<ControlBinding>]
    let picker: (ControlProfileEditorControl<ControlBinding>) -> PickerContent

    var body: some View {
        Form {
            Section {
                TextField("NAME", text: $name)
                Picker("SYSTEM", selection: $system) {
                    Text("ANY").tag(GameSystem.unknown)
                    ForEach(GameSystem.concreteCases, id: \.self) { system in
                        Text(system.string).tag(system)
                    }
                }
            }

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
