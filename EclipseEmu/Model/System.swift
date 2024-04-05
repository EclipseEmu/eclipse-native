import Foundation

@objc(ECSystem)
public enum GameSystem: Int16 {
    case unknown = 0
    case gb = 1
    case gbc = 2
    case gba = 3
    case nes = 4
    case snes = 5
    
    var string: String {
        return switch self {
        case .unknown:
            "Unknown System"
        case .gb:
            "Game Boy"
        case .gbc:
            "Game Boy Color"
        case .gba:
            "Game Boy Advance"
        case .nes:
            "Nintendo Entertainment System"
        case .snes:
            "Super Nintendo Entertainment System"
        }
    }
}
