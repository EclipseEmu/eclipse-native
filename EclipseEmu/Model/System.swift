import Foundation
import UniformTypeIdentifiers

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
    
    static func from(homebrew: String) -> Self {
        return switch homebrew.lowercased() {
        case "gb": Self.gb
        case "gbc": Self.gbc
        case "gba": Self.gba
        case "nes": Self.nes
        case "snes": Self.snes
        default: Self.unknown
        }
    }
    
    static func from(fileType: UTType) -> Self {
        return switch fileType.identifier {
        case "dev.magnetar.eclipseemu.rom.gb": Self.gb
        case "dev.magnetar.eclipseemu.rom.gbc": Self.gbc
        case "dev.magnetar.eclipseemu.rom.gba": Self.gba
        case "dev.magnetar.eclipseemu.rom.nes": Self.nes
        case "dev.magnetar.eclipseemu.rom.snes": Self.snes
        default: Self.unknown
        }
    }
}
