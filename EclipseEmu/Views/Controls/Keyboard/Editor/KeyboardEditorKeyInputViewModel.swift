import SwiftUI
import GameController

final class KeyboardEditorKeyInputViewModel: ObservableObject {
    var previousKeyboardHandler: GCKeyboardValueChangedHandler?
    @Published var selected: Binding<GCKeyCode?>?
    @Published var isFocused: Bool = false
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

    func handleKeyboardConnection(_: Notification) {
        self.currentKeyboard = GCKeyboard.coalesced
        guard let keyboard = currentKeyboard?.keyboardInput else { return }
        keyboard.keyChangedHandler = handleInput
    }

    func handleInput(keyboard: GCKeyboardInput, _: GCControllerButtonInput, keycode: GCKeyCode, _: Bool) {
        guard let selected else { return }
        selected.wrappedValue = keycode
        self.selected = nil
        self.isFocused = false
    }
}
