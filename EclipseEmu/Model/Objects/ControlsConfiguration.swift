import EclipseKit

extension ControlsConfigurationObject {
    var system: GameSystem {
        get {
            GameSystem(rawValue: UInt32(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int32(newValue.rawValue)
        }
    }

    var kind: ControlsInputSourceKind {
        get {
            ControlsInputSourceKind(rawValue: self.rawKind) ?? .unknown
        }
        set {
            self.rawKind = newValue.rawValue
        }
    }
}
