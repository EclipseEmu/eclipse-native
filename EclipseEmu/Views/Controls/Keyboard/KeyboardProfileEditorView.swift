import SwiftUI
import EclipseKit
import GameController

private final class KeyboardProfilesEditorViewModel: ObservableObject {
    var previousKeyboardHandler: GCKeyboardValueChangedHandler?
    @Published var selected: ControlProfileEditorControl<KeyboardProfileEditorBinding>?
    @Published var currentKeyboard: GCKeyboard? = GCKeyboard.coalesced

    @inlinable
    var currentKeyboardInput: GCKeyboardInput? {
        currentKeyboard?.keyboardInput
    }

    func viewAppeared() {
        guard let currentKeyboardInput else { return }
        previousKeyboardHandler = currentKeyboardInput.keyChangedHandler
        currentKeyboardInput.keyChangedHandler = handleInput
    }

    func viewDisappeared() {
        guard let currentKeyboardInput else { return }
        currentKeyboardInput.keyChangedHandler = previousKeyboardHandler
    }

    func handleKeyboardConnected(_: Notification) {
        self.currentKeyboard = GCKeyboard.coalesced
        guard let keyboard = currentKeyboard?.keyboardInput else { return }
        keyboard.keyChangedHandler = handleInput
    }

    func handleInput(keyboard: GCKeyboardInput, _: GCControllerButtonInput, keycode: GCKeyCode, _: Bool) {
        guard let selected else { return }
        selected.binding = .init(display: keycode.displayName, value: keycode.rawValue)
        self.selected = nil
    }
}

struct KeyboardProfileEditorBinding {
    let display: String
    let value: GCKeyCode.RawValue
}

private struct KeyboardProfileEditorInputView: View {
    @ObservedObject var viewModel: KeyboardProfilesEditorViewModel
    @ObservedObject var control: ControlProfileEditorControl<KeyboardProfileEditorBinding>
    var focusState: FocusState<ControlProfileEditorControl<KeyboardProfileEditorBinding>?>.Binding

    let data: Binding<String> = .init(get: { "" }, set: { _ in })

    var body: some View {
        ZStack {
            TextField("", text: data)
                .labelsHidden()
                .focused(focusState, equals: control)
                .frame(width: 0, height: 0)
                .fixedSize()
                .opacity(0)
                .modify {
                    if #available(iOS 17.0, macOS 14.0, *) {
                        $0.onKeyPress(.escape) { .handled }.onKeyPress(.return) { .handled }
                    } else {
                        $0
                    }
                }
                .allowsHitTesting(false)

            Button {
                withAnimation {
                    viewModel.selected = control
                    focusState.wrappedValue = control
                }
            } label: {
                Text(verbatim: control.binding?.display, fallback: "UNBOUND")
                    .padding(.vertical, 4.0)
                    .padding(.horizontal, 4.0)
                    .contentShape(Rectangle())
                    .foregroundStyle(
                        viewModel.selected == control
                            ? Color.accentColor
                            : control.binding != nil ? Color.primary : Color.secondary
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .contentShape(.rect)
            }
            .disabled(viewModel.currentKeyboard == nil)
            .buttonStyle(.plain)
            .multilineTextAlignment(.leading)
#if os(macOS)
            .pointerStyle(.horizontalText)
#endif
        }
        .contextMenu {
            Button {
                control.binding = nil
            } label: {
                Label("UNBIND", systemImage: "xmark.circle")
            }
            .buttonStyle(.borderless)
            .disabled(control.binding == nil)
        }
    }
}

struct KeyboardProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    @FocusState private var focusState: ControlProfileEditorControl<KeyboardProfileEditorBinding>?
    @State var name: String
    @State var system: GameSystem
    let inputs: [ControlProfileEditorContolCollection<KeyboardProfileEditorBinding>]
    @StateObject private var viewModel = KeyboardProfilesEditorViewModel()

    private let existingObject: ObjectBox<InputSourceKeyboardProfileObject>?

    init(for target: EditorTarget<InputSourceKeyboardProfileObject>) {
        switch target {
        case .create:
            name = ""
            system = .unknown
            inputs = GameInput.sectioned.map { .init(items: $0.items.map { .init(input: $0) }) }
            existingObject = nil
        case .edit(let profile):
            name = profile.name ?? ""
            system = profile.system
            inputs = GameInput.sectioned.map { .init(items: $0.items.map { .init(input: $0) }) }
            existingObject = .init(profile)
        }
    }

    var body: some View {
        ControlsProfileEditorView(name: $name, system: $system, inputs: inputs) { control in
            LabeledContent {
                KeyboardProfileEditorInputView(viewModel: viewModel, control: control, focusState: $focusState)
            } label: {
                Label(control.input.string, systemImage: control.input.systemImage)
            }
        }
        .onAppear(perform: viewModel.viewAppeared)
        .onDisappear(perform: viewModel.viewDisappeared)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("CANCEL", action: dismiss)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(existingObject == nil ? "CREATE" : "SAVE", action: done)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCKeyboardDidConnect), perform: viewModel.handleKeyboardConnected)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    func done() {
        Task {
            print(inputs)
            dismiss()
        }
    }
}

#Preview {
    KeyboardProfileEditorView(for: .create)
}
