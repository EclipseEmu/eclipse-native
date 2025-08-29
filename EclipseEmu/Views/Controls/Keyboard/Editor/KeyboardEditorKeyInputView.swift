import SwiftUI
import EclipseKit
import GameController

struct KeyboardEditorKeyInputView: View {
    /// NOTE: This is needed because `.const(value)` can be detected by some views, making them disabled.
    static let textFieldBinding: Binding<String> = .init(get: { "" }, set: { _ in })
    
    @StateObject private var viewModel: KeyboardEditorKeyInputViewModel = .init()
    @Binding private var keycode: GCKeyCode?
    @Binding private var isDuplicate: Bool
    @FocusState private var isFocused: Bool

    init(keycode: Binding<GCKeyCode?>, isDuplicate: Binding<Bool>) {
        self._keycode = keycode
        self._isDuplicate = isDuplicate
    }
    
    var body: some View {
        ZStack {
            TextField("", text: KeyboardEditorKeyInputView.textFieldBinding)
                .labelsHidden()
                .frame(width: 0, height: 0)
                .fixedSize()
                .opacity(0)
                .allowsHitTesting(false)
                .focused($isFocused)
               .ignoreKeyboardFeedbackSound(for: [.escape, .return])
               .onChange(of: isFocused) { newValue in
                   viewModel.isFocused = newValue
               }

            Button(action: focus) {
                Text(verbatim: keycode?.displayName, fallback: "UNBOUND")
                    .padding(.vertical, 4.0)
                    .padding(.horizontal, 4.0)
                    .contentShape(Rectangle())
                    .foregroundStyle(color)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                    .contentShape(.rect)
            }
            .disabled(viewModel.currentKeyboard == nil)
            .buttonStyle(.plain)
            .multilineTextAlignment(.leading)
            .onAppear(perform: viewModel.viewAppeared)
            .onDisappear(perform: viewModel.viewDisappeared)
            .onReceive(NotificationCenter.default.publisher(for: .GCKeyboardDidConnect), perform: viewModel.handleKeyboardConnection)
            .onReceive(NotificationCenter.default.publisher(for: .GCKeyboardDidDisconnect), perform: viewModel.handleKeyboardConnection)
#if os(macOS)
            .modify {
                if #available(macOS 15.0, *) {
                    $0.pointerStyle(.horizontalText)
                } else {
                    $0
                }
            }
#endif
        }
    }
    
    private var color: Color {
        if viewModel.isFocused {
            Color.accentColor
        } else if isDuplicate {
            Color.red
        } else if keycode == nil {
            Color.secondary
        } else {
            Color.primary
        }
    }
    
    private func focus() {
        withAnimation {
            viewModel.selected = $keycode
            viewModel.isFocused = true
            isFocused = true
        }
    }
}
