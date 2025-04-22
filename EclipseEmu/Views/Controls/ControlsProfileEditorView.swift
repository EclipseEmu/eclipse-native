import SwiftUI
import EclipseKit

struct ControlsProfileEditorView<PickerContent: View>: View {
    @Binding var name: String
    @Binding var system: GameSystem
    let picker: (GameInput) -> PickerContent

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

            ForEach(GameInput.sectioned) { section in
                Section {
                    ForEach(section.items, id: \.rawValue) { input in
                        picker(input).hidden(if: !system.inputs.contains(input))
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
