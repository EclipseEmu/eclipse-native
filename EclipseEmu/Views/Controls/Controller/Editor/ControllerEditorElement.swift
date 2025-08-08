import SwiftUI

protocol ControllerEditorElement: Identifiable, Hashable {
    associatedtype Binding: ControllerControlBinding
    
    var id: String { get }
    var key: ControllerControl { get set }
    var binding: Binding? { get set }
    
    init(key: ControllerControl, binding: Binding?)
    
    func label(inputNaming: ControlNamingConvention) -> String?
}

protocol ControllerControlBinding: Hashable {}
extension ControllerMappings.ButtonBinding: ControllerControlBinding {}
extension ControllerMappings.DirectionalBinding: ControllerControlBinding {}

struct ControllerEditorDirectionalElement: ControllerEditorElement {
    @usableFromInline
    var id: String { self.key.id }
    var key: ControllerControl
    var binding: ControllerMappings.DirectionalBinding?
    
    func label(inputNaming: ControlNamingConvention) -> String? {
        return binding?.input.label(for: inputNaming).0
    }
}

struct ControllerEditorButtonElement: ControllerEditorElement {
    @usableFromInline
    var id: String { self.key.id }
    var key: ControllerControl
    var binding: ControllerMappings.ButtonBinding?
    
    func label(inputNaming: ControlNamingConvention) -> String? {
        return binding?.input.label(for: inputNaming).0
    }
}
