struct ControllerEditorExtendedProfile {
    var buttonA: ControllerEditorButtonElement
    var buttonB: ControllerEditorButtonElement
    var buttonX: ControllerEditorButtonElement
    var buttonY: ControllerEditorButtonElement
    var directionPad: ControllerEditorDirectionalElement
    var leftThumbstick: ControllerEditorDirectionalElement
    var leftThumbstickButton: ControllerEditorButtonElement
    var rightThumbstick: ControllerEditorDirectionalElement
    var rightThumbstickButton: ControllerEditorButtonElement
    var leftShoulder: ControllerEditorButtonElement
    var rightShoulder: ControllerEditorButtonElement
    var leftTrigger: ControllerEditorButtonElement
    var rightTrigger: ControllerEditorButtonElement
    var buttonHome: ControllerEditorButtonElement
    var buttonMenu: ControllerEditorButtonElement
    var buttonOptions: ControllerEditorButtonElement
    var buttonShare: ControllerEditorButtonElement
    var xboxPaddleOne: ControllerEditorButtonElement
    var xboxPaddleTwo: ControllerEditorButtonElement
    var xboxPaddleThree: ControllerEditorButtonElement
    var xboxPaddleFour: ControllerEditorButtonElement
    var dualShockTouchpadOne: ControllerEditorDirectionalElement
    var dualShockTouchpadTwo: ControllerEditorDirectionalElement
    var dualShockTouchpadButton: ControllerEditorButtonElement
    
    init(from mappings: ControllerMappings) {
        self.buttonA = Self.button(from: mappings, key: .buttonA)
        self.buttonB = Self.button(from: mappings, key: .buttonB)
        self.buttonX = Self.button(from: mappings, key: .buttonX)
        self.buttonY = Self.button(from: mappings, key: .buttonY)
        self.directionPad = Self.directional(from: mappings, key: .directionPad)
        self.leftThumbstick = Self.directional(from: mappings, key: .leftThumbstick)
        self.leftThumbstickButton = Self.button(from: mappings, key: .leftThumbstickButton)
        self.rightThumbstick = Self.directional(from: mappings, key: .rightThumbstick)
        self.rightThumbstickButton = Self.button(from: mappings, key: .rightThumbstickButton)
        self.leftShoulder = Self.button(from: mappings, key: .leftShoulder)
        self.rightShoulder = Self.button(from: mappings, key: .rightShoulder)
        self.leftTrigger = Self.button(from: mappings, key: .leftTrigger)
        self.rightTrigger = Self.button(from: mappings, key: .rightTrigger)
        self.buttonHome = Self.button(from: mappings, key: .buttonHome)
        self.buttonMenu = Self.button(from: mappings, key: .buttonMenu)
        self.buttonOptions = Self.button(from: mappings, key: .buttonOptions)
        self.buttonShare = Self.button(from: mappings, key: .buttonShare)
        self.xboxPaddleOne = Self.button(from: mappings, key: .xboxPaddleOne)
        self.xboxPaddleTwo = Self.button(from: mappings, key: .xboxPaddleTwo)
        self.xboxPaddleThree = Self.button(from: mappings, key: .xboxPaddleThree)
        self.xboxPaddleFour = Self.button(from: mappings, key: .xboxPaddleFour)
        self.dualShockTouchpadOne = Self.directional(from: mappings, key: .dualShockTouchpadOne)
        self.dualShockTouchpadTwo = Self.directional(from: mappings, key: .dualShockTouchpadTwo)
        self.dualShockTouchpadButton = Self.button(from: mappings, key: .dualShockTouchpadButton)
    }
    
    private static func button(from mappings: ControllerMappings, key: ControllerControl) -> ControllerEditorButtonElement {
        return if case .button(let i) = mappings.bindings[key.id] {
            .init(key: key, binding: mappings.buttons[i])
        } else {
            .init(key: key, binding: nil)
        }
    }
    
    private static func directional(from mappings: ControllerMappings, key: ControllerControl) -> ControllerEditorDirectionalElement {
        return if case .directional(let i) = mappings.bindings[key.id] {
            .init(key: key, binding: mappings.directionals[i])
        } else {
            .init(key: key, binding: nil)
        }
    }
    
    mutating func update(_ button: ControllerEditorButtonElement) {
        switch button.key {
        case .buttonA: buttonA = button
        case .buttonB: buttonB = button
        case .buttonX: buttonX = button
        case .buttonY: buttonY = button
        case .leftThumbstickButton: leftThumbstickButton = button
        case .rightThumbstickButton: rightThumbstickButton = button
        case .leftShoulder: leftShoulder = button
        case .rightShoulder: rightShoulder = button
        case .leftTrigger: leftTrigger = button
        case .rightTrigger: rightTrigger = button
        case .buttonHome: buttonHome = button
        case .buttonMenu: buttonMenu = button
        case .buttonOptions: buttonOptions = button
        case .buttonShare: buttonShare = button
        case .xboxPaddleOne: xboxPaddleOne = button
        case .xboxPaddleTwo: xboxPaddleTwo = button
        case .xboxPaddleThree: xboxPaddleThree = button
        case .xboxPaddleFour: xboxPaddleFour = button
        case .dualShockTouchpadButton: dualShockTouchpadButton = button
        default: break
        }
    }
    
    mutating func update(_ directional: ControllerEditorDirectionalElement) {
        switch directional.key {
        case .directionPad: directionPad = directional
        case .leftThumbstick: leftThumbstick = directional
        case .rightThumbstick: rightThumbstick = directional
        case .dualShockTouchpadOne: dualShockTouchpadOne = directional
        case .dualShockTouchpadTwo: dualShockTouchpadTwo = directional
        default: break
        }
    }
}

extension ControllerMappings {
    init(from profile: ControllerEditorExtendedProfile) {
        self.bindings = [:]
        self.buttons = []
        self.directionals = []
        
        addButton(profile.buttonA)
        addButton(profile.buttonB)
        addButton(profile.buttonX)
        addButton(profile.buttonY)
        addButton(profile.leftThumbstickButton)
        addButton(profile.rightThumbstickButton)
        addButton(profile.leftShoulder)
        addButton(profile.rightShoulder)
        addButton(profile.leftTrigger)
        addButton(profile.rightTrigger)
        addButton(profile.buttonHome)
        addButton(profile.buttonMenu)
        addButton(profile.buttonOptions)
        addButton(profile.buttonShare)
        addButton(profile.xboxPaddleOne)
        addButton(profile.xboxPaddleTwo)
        addButton(profile.xboxPaddleThree)
        addButton(profile.xboxPaddleFour)
        addButton(profile.dualShockTouchpadButton)
        
        addDirectional(profile.directionPad)
        addDirectional(profile.leftThumbstick)
        addDirectional(profile.rightThumbstick)
        addDirectional(profile.dualShockTouchpadOne)
        addDirectional(profile.dualShockTouchpadTwo)
    }
    
    private mutating func addButton(_ element: ControllerEditorButtonElement) {
        guard let binding = element.binding else { return }
        let i = self.buttons.count
        self.buttons.append(binding)
        self.bindings[element.key.id] = .button(i)
    }
    
    private mutating func addDirectional(_ element: ControllerEditorDirectionalElement) {
        guard let binding = element.binding else { return }
        let i = self.directionals.count
        self.directionals.append(binding)
        self.bindings[element.key.id] = .directional(i)
    }
}
