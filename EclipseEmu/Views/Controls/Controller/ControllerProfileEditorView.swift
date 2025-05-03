import SwiftUI
import EclipseKit
import GameController

enum EditorTarget<Item: Identifiable & Hashable>: Hashable, Equatable {
    case create
    case edit(Item)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.create, .create): true
        case (.edit(let lhs), .edit(let rhs)): lhs.id == rhs.id
        default: false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .create:
            true.hash(into: &hasher)
        case .edit(let item):
            item.hash(into: &hasher)
        }
    }
}

struct ControllerProfileInputView: View {
    private let input: GameInput
    @State private var value: String = ""

    init(input: GameInput) {
        self.input = input
    }

    var body: some View {
        Picker(selection: $value) {
            Text("CONTROL_UNBOUND").tag("")
        } label: {
            Label(input.string, systemImage: input.systemImage)
        }
    }
}

struct ControllerProfileEditorBinding {
    var display: String
    var value: InputSourceControllerBinding
}

struct ControllerProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    @State var name: String
    @State var system: GameSystem
    let inputs: [ControlProfileEditorContolCollection<ControllerProfileEditorBinding>]
    private let existingObject: ObjectBox<InputSourceControllerProfileObject>?

    init(for target: EditorTarget<InputSourceControllerProfileObject>) {
        switch target {
        case .create:
            name = ""
            system = .unknown
            existingObject = nil
            inputs = GameInput.sectioned.map { .init(items: $0.items.map { .init(input: $0) }) }
        case .edit(let profile):
            name = profile.name ?? ""
            system = profile.system
            existingObject = .init(profile)
            // FIXME: load the bound values
            inputs = GameInput.sectioned.map { .init(items: $0.items.map { .init(input: $0) }) }
        }
    }

    var body: some View {
        ControlsProfileEditorView(name: $name, system: $system, inputs: inputs) { binding in
            LabeledContent {} label: {
                Label(binding.input.string, systemImage: binding.input.systemImage)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("CANCEL", action: dismiss)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(existingObject == nil ? "CREATE" : "SAVE", action: done)
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    func done() {
        Task {
            dismiss()
        }
    }
}

#Preview {
    ControllerProfileEditorView(for: .create)
}
