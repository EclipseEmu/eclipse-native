import EclipseKit
import GameController

final class KeyboardEditorViewModel: ObservableObject {
    let onChange: ControlsProfileUpdateCallback<InputSourceKeyboardDescriptor>
    let system: System
    let namingConvention: ControlNamingConvention
    
    @Published var elements: [KeyboardEditorElement]
    
    init(
        onChange: @escaping ControlsProfileUpdateCallback<InputSourceKeyboardDescriptor>,
        bindings: KeyboardMappings,
        system: System
    ) {
        self.onChange = onChange
        self.system = system
        self.namingConvention = system.controlNamingConvention

        self.elements = bindings.map { key, mapping in
            .init(keycode: key, mapping: mapping)
        }
        self.elements.sort()
    }
    
    func isDuplicate(old initialKey: GCKeyCode?, new newKey: GCKeyCode) -> Bool {
        guard initialKey != newKey else { return false }
        for element in elements {
            if element.keycode == newKey {
                return true
            }
        }
        return false
    }
    
    func insertElement(keycode: GCKeyCode, mapping: KeyboardMapping) {
        elements.sortedInsert(.init(keycode: keycode, mapping: mapping))
        didUpdate()
    }
    
    func updateElement(_ index: Int, keycode: GCKeyCode, mapping: KeyboardMapping) {
        elements[index].keycode = keycode
        elements[index].mapping = mapping
        didUpdate()
    }

    func deleteElements(_ indices: IndexSet) {
        elements.remove(atOffsets: indices)
        didUpdate()
    }

    func didUpdate() {
        var bindings: KeyboardMappings = [:]
        for element in elements {
            bindings[element.keycode] = element.mapping
        }
        self.onChange(bindings)
    }
}
