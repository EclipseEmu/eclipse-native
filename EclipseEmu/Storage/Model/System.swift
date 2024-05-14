import Foundation
import UniformTypeIdentifiers
import EclipseKit

extension GameSystem {
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
