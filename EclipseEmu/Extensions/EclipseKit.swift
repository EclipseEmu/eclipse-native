import SwiftUI
import AVFoundation
import EclipseKit
import Metal

// MARK: System

extension GameSystem {
    var string: LocalizedStringKey {
        return switch self {
        case .unknown: "SYSTEM_UNKNOWN"
        case .gb: "SYSTEM_GB"
        case .gbc: "SYSTEM_GBC"
        case .gba: "SYSTEM_GBA"
        case .nes: "SYSTEM_NES"
        case .snes: "SYSTEM_SNES"
        @unknown default: "SYSTEM_UNKNOWN"
        }
    }

    var fileType: UTType? {
        return switch self {
        case .gb: .romGB
        case .gbc: .romGBC
        case .gba: .romGBA
        case .nes: .romNES
        case .snes: .romSNES
        default: nil
        }
    }

    init(fileType: UTType) {
        self = switch fileType.identifier {
        case UTType.romGB.identifier: Self.gb
        case UTType.romGBC.identifier: Self.gbc
        case UTType.romGBA.identifier: Self.gba
        case UTType.romNES.identifier: Self.nes
        case UTType.romSNES.identifier: Self.snes
        default: Self.unknown
        }
    }

    var inputs: GameInput {
        switch self {
        case .unknown: GameInput.allOn
        case .gb, .gbc, .nes:
            [.dpadDown, .dpadUp, .dpadLeft, .dpadRight, .faceButtonRight, .faceButtonDown, .startButton, .selectButton]
        case .gba:
            [
                .dpadDown, .dpadUp, .dpadLeft, .dpadRight,
                .faceButtonRight, .faceButtonDown,
                .startButton, .selectButton,
                .shoulderLeft, .shoulderRight
            ]
        case .snes:
            [
                .dpadDown, .dpadUp, .dpadLeft, .dpadRight,
                .faceButtonRight, .faceButtonDown, .faceButtonLeft, .faceButtonUp,
                .startButton, .selectButton, .shoulderLeft, .shoulderRight
            ]
        @unknown default:
            []
        }
    }
}

extension GameSystem: Codable {}

extension GameSystem: @retroactive CaseIterable {
    public static let concreteCases: [GameSystem] = [.gb, .gbc, .gba, .nes, .snes]
    public static let allCases: [GameSystem] = [.unknown, .gb, .gbc, .gba, .nes, .snes]
}

// MARK: Video

extension GameCoreVideoPixelFormat {
    var metal: MTLPixelFormat? {
        return switch self {
        case .bgra8Unorm: .bgra8Unorm
        case .rgba8Unorm: .rgba8Unorm
        default: nil
        }
    }
}

// MARK: Audio

extension GameCoreCommonAudioFormat {
    var avCommonFormat: AVAudioCommonFormat {
        return switch self {
        case .pcmFloat32: .pcmFormatFloat32
        case .pcmFloat64: .pcmFormatFloat64
        case .pcmInt16: .pcmFormatInt16
        case .pcmInt32: .pcmFormatInt32
        default: .otherFormat
        }
    }
}

extension GameCoreAudioFormat {
    var avAudioFormat: AVAudioFormat? {
        AVAudioFormat(
            commonFormat: self.commonFormat.avCommonFormat,
            sampleRate: self.sampleRate,
            channels: self.channelCount,
            interleaved: true
        )
    }
}

// MARK: Cheats

extension GameCoreCheatCharacterSet {
    var swiftCharacterSet: CharacterSet {
        switch self {
        case .hexadecimal: .hexadecimal
        @unknown default: .hexadecimal
        }
    }
}

// MARK: Core

extension GameCoreInfo: @retroactive @unchecked Sendable {}

extension GameCoreInfo: @retroactive Equatable {
    public static func == (lhs: GameCoreInfo, rhs: GameCoreInfo) -> Bool {
        lhs.id == rhs.id
    }
}

extension GameCoreInfo: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
