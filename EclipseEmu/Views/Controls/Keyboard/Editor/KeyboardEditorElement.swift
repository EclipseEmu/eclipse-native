import GameController

struct KeyboardEditorElement: Identifiable, Hashable, Comparable {
    var keycode: GCKeyCode
    var mapping: KeyboardMapping
    @usableFromInline
    var id: GCKeyCode { self.keycode }
    
    init(keycode: GCKeyCode, mapping: KeyboardMapping) {
        self.keycode = keycode
        self.mapping = mapping
    }
    
    func hash(into hasher: inout Hasher) {
        self.keycode.hash(into: &hasher)
        self.mapping.direction.hash(into: &hasher)
        self.mapping.input.hash(into: &hasher)
    }
    
    static func == (lhs: KeyboardEditorElement, rhs: KeyboardEditorElement) -> Bool {
        lhs.keycode == rhs.keycode &&
        lhs.mapping.input == rhs.mapping.input &&
        lhs.mapping.direction == rhs.mapping.direction
    }
    
    static func < (lhs: KeyboardEditorElement, rhs: KeyboardEditorElement) -> Bool {
        lhs.keycode.rawValue < rhs.keycode.rawValue
    }
}
