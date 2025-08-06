import SwiftUI
import EclipseKit
import GameController

struct KeyboardEditorKeyInputView: View {
    static let textFieldBinding: Binding<String> = .init(get: { "" }, set: { _ in })
    
    @StateObject var viewModel: KeyboardEditorKeyInputViewModel = .init()
    @Binding var keycode: GCKeyCode?
    @FocusState private var isFocused: Bool
    @Binding var isDuplicate: Bool
    
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

            Button {
                withAnimation {
                    viewModel.selected = $keycode
                    viewModel.isFocused = true
                    isFocused = true
                }
            } label: {
                Text(verbatim: keycode?.displayName, fallback: "UNBOUND")
                    .padding(.vertical, 4.0)
                    .padding(.horizontal, 4.0)
                    .contentShape(Rectangle())
                    .foregroundStyle(
                        viewModel.isFocused
                            ? Color.accentColor
                            : isDuplicate
                                ? Color.red
                                : keycode == nil
                                    ? Color.secondary
                                    : Color.primary
                    )
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
}
