import EclipseKit
import Foundation
import UniformTypeIdentifiers

extension GameSystem {
    init(fileType: UTType) {
        self = switch fileType.identifier {
        case "dev.magnetar.eclipseemu.rom.gb": Self.gb
        case "dev.magnetar.eclipseemu.rom.gbc": Self.gbc
        case "dev.magnetar.eclipseemu.rom.gba": Self.gba
        case "dev.magnetar.eclipseemu.rom.nes": Self.nes
        case "dev.magnetar.eclipseemu.rom.snes": Self.snes
        default: Self.unknown
        }
    }

    @available(*, deprecated, renamed: "GameSystem(fileType:)", message: "Use the initializer instead")
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
