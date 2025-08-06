import SwiftUI
import EclipseKit
import GameController

enum ControllerInputTag: UInt8, RawRepresentable, Equatable, Hashable {
    case none   = 0
    case up     = 1
    case down   = 2
    case left   = 3
    case right  = 4
}

struct ControllerInput: Hashable, Equatable, Identifiable {
    let id: String
    let tag: ControllerInputTag

    init(rawValue: String, tag: ControllerInputTag = .none) {
        self.id = rawValue
        self.tag = tag
    }

    static let buttonA                  = Self(rawValue: GCInputButtonA)
    static let buttonB                  = Self(rawValue: GCInputButtonB)
    static let buttonX                  = Self(rawValue: GCInputButtonX)
    static let buttonY                  = Self(rawValue: GCInputButtonY)
    static let directionPad             = Self(rawValue: GCInputDirectionPad)
    static let leftThumbstick           = Self(rawValue: GCInputLeftThumbstick)
    static let rightThumbstick          = Self(rawValue: GCInputRightThumbstick)
    static let leftShoulder             = Self(rawValue: GCInputLeftShoulder)
    static let rightShoulder            = Self(rawValue: GCInputRightShoulder)
    static let leftTrigger              = Self(rawValue: GCInputLeftTrigger)
    static let rightTrigger             = Self(rawValue: GCInputRightTrigger)
    static let leftThumbstickButton     = Self(rawValue: GCInputLeftThumbstickButton)
    static let rightThumbstickButton    = Self(rawValue: GCInputRightThumbstickButton)
    static let buttonHome               = Self(rawValue: GCInputButtonHome)
    static let buttonMenu               = Self(rawValue: GCInputButtonMenu)
    static let buttonOptions            = Self(rawValue: GCInputButtonOptions)
    static let buttonShare              = Self(rawValue: GCInputButtonShare)
    static let xboxPaddleOne            = Self(rawValue: GCInputXboxPaddleOne)
    static let xboxPaddleTwo            = Self(rawValue: GCInputXboxPaddleTwo)
    static let xboxPaddleThree          = Self(rawValue: GCInputXboxPaddleThree)
    static let xboxPaddleFour           = Self(rawValue: GCInputXboxPaddleFour)
    static let dualShockTouchpadOne     = Self(rawValue: GCInputDualShockTouchpadOne)
    static let dualShockTouchpadTwo     = Self(rawValue: GCInputDualShockTouchpadTwo)
    static let dualShockTouchpadButton  = Self(rawValue: GCInputDualShockTouchpadButton)
    
    var display: LocalizedStringKey {
        switch self {
        case .buttonA:                  "CONTROLLER_BUTTON_A"
        case .buttonB:                  "CONTROLLER_BUTTON_B"
        case .buttonX:                  "CONTROLLER_BUTTON_X"
        case .buttonY:                  "CONTROLLER_BUTTON_Y"
        case .directionPad:             "CONTROLLER_DPAD"
        case .leftThumbstick:           "CONTROLLER_LEFT_THUMBSTICK"
        case .rightThumbstick:          "CONTROLLER_RIGHT_THUMBSTICK"
        case .leftShoulder:             "CONTROLLER_LEFT_SHOULDER"
        case .rightShoulder:            "CONTROLLER_RIGHT_SHOULDER"
        case .leftTrigger:              "CONTROLLER_LEFT_TRIGGER"
        case .rightTrigger:             "CONTROLLER_RIGHT_TRIGGER"
        case .leftThumbstickButton:     "CONTROLLER_LEFT_THUMBSTICK_BUTTON"
        case .rightThumbstickButton:    "CONTROLLER_LEFT_THUMBSTICK_BUTTON"
        case .buttonHome:               "CONTROLLER_HOME"
        case .buttonMenu:               "CONTROLLER_MENU"
        case .buttonOptions:            "CONTROLLER_OPTIONS"
        case .buttonShare:              "CONTROLLER_SHARE"
        case .xboxPaddleOne:            "CONTROLLER_XBOX_PADDLE_ONE"
        case .xboxPaddleTwo:            "CONTROLLER_XBOX_PADDLE_TWO"
        case .xboxPaddleThree:          "CONTROLLER_"
        case .xboxPaddleFour:           "CONTROLLER_"
        case .dualShockTouchpadOne:     "CONTROLLER_"
        case .dualShockTouchpadTwo:     "CONTROLLER_"
        case .dualShockTouchpadButton:  "CONTROLLER_"
        default: "UNKNOWN"
        }
    }

    var systemImage: String {
        return ""
    }
}

private struct ControllerInputView: View {
    private let display: LocalizedStringKey
    private let systemImage: String
    private let value: ControllerInput
    @Binding private var picker: ControllerInput?

    init(_ display: LocalizedStringKey, systemImage: String, value: ControllerInput, picker: Binding<ControllerInput?>) {
        self.display = display
        self.systemImage = systemImage
        self.value = value
        self._picker = picker
    }

    var body: some View {
        LabeledContent {
            Button("UNBOUND") {
                self.picker = value
            }
        } label: {
            Label(display, systemImage: systemImage)
        }
        .tag(value)
    }
}


struct ControllerProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    @State var name: String
    @State var system: System
    private let existingObject: ObjectBox<ControllerProfileObject>?
    @State private var pickerTarget: ControllerInput?

    init(for target: EditorTarget<ControllerProfileObject>) {
        switch target {
        case .create:
            name = ""
            system = .unknown
            existingObject = nil
        case .edit(let profile):
            name = profile.name ?? ""
            system = profile.system
            existingObject = .init(profile)
        }
    }

    var body: some View {
        Form {
            Section {
                ControllerInputView("CONTROLLER_BUTTON_A", systemImage: "", value: .buttonA, picker: $pickerTarget)
                ControllerInputView("CONTROLLER_BUTTON_B", systemImage: "", value: .buttonB, picker: $pickerTarget)
                ControllerInputView("CONTROLLER_BUTTON_X", systemImage: "", value: .buttonX, picker: $pickerTarget)
                ControllerInputView("CONTROLLER_BUTTON_Y", systemImage: "", value: .buttonY, picker: $pickerTarget)
            }
        }
        .sheet(item: $pickerTarget) { input in
            Text(verbatim: input.id)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("CANCEL", action: dismiss)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(existingObject == nil ? "CREATE" : "SAVE", action: done)
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    func done() {
        Task {
            dismiss()
        }
    }
}

#Preview {
    ControllerProfileEditorView(for: .create)
}
