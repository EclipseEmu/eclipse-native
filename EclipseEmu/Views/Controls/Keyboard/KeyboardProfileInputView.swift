import SwiftUI
import Combine
import EclipseKit
import GameController

#if os(macOS)
struct KeyboardProfileInputView: View {
    let input: GameInput
    @FocusState private var focusState: GameInput.RawValue?
    @State private var value: GCKeyCode?

    var label: Text {
        if let value {
            Text(verbatim: value.displayName, fallback: "UNKNOWN_KEY \(value.rawValue)")
        } else {
            Text("CONTROL_UNBOUND")
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        LabeledContent {
            VStack {
                Button {
                    focusState = input.rawValue
                } label: {
                    label
                        .frame(width: 120)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .foregroundStyle(.primary)
                }
                .background(
                    Rectangle()
                        .foregroundStyle(.background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: .infinity)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.tertiary)
                )
                .clipShape(RoundedRectangle(cornerRadius: .infinity))
                .buttonStyle(.borderless)
                .focusable()
                .focused($focusState, equals: input.rawValue)
                .onKeyPress { _ in .handled }
                .onReceive(Just(focusState)) { focusState in
                    guard
                        focusState == input.rawValue,
                        let keyboardInput = GCKeyboard.coalesced?.keyboardInput
                    else { return }
                    keyboardInput.keyChangedHandler = handleKeypress
                }
            }
        } label: {
            Label(input.string, systemImage: input.systemImage)
        }
    }

    func handleKeypress(input: GCKeyboardInput, _: GCControllerButtonInput, keyCode: GCKeyCode, _: Bool) -> Void {
        focusState = nil
        input.keyChangedHandler = nil
        self.value = keyCode
    }
}
#else
struct KeyboardProfileInputView: View {
    let input: GameInput

    var body: some View {
        EmptyView()
    }
}
#endif

@available(iOS 18.0, *)
#Preview {
    Form {
        KeyboardProfileInputView(input: .faceButtonDown)
        KeyboardProfileInputView(input: .faceButtonUp)
    }
    .formStyle(.grouped)
}
