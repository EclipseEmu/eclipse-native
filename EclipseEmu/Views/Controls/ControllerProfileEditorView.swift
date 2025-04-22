import SwiftUI
import EclipseKit
import GameController

enum ControllerProfileEditorTarget: Hashable, Equatable {
    case create
    case edit(ControllerProfile)

    static func == (lhs: ControllerProfileEditorTarget, rhs: ControllerProfileEditorTarget) -> Bool {
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
        case .edit(let id):
            id.hash(into: &hasher)
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
            Text("CONTROL_UNBOUND")
                .tag("")
            Text("Right Thumbstick Up")
                .tag(GCInputLeftThumbstick)
        } label: {
            Label(input.string, systemImage: input.systemImage)
        }
    }
}

struct ControllerProfileEditorView: View {
    @State var name: String
    @State var system: GameSystem

    init(for target: ControllerProfileEditorTarget) {
        switch target {
        case .create:
            name = ""
            system = .unknown
        case .edit(let profile):
            name = profile.name
            system = profile.system
        }
    }

    var body: some View {
        ControlsProfileEditorView(name: $name, system: $system) { input in
            ControllerProfileInputView(input: input)
        }
    }
}

#Preview {
    ControllerProfileEditorView(for: .create)
}
