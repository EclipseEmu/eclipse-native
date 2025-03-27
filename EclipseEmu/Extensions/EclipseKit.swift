import AVFoundation
import EclipseKit
import Metal

extension GameSystem {
    var string: String {
        return switch self {
        case .unknown: "Unknown System"
        case .gb: "Game Boy"
        case .gbc: "Game Boy Color"
        case .gba: "Game Boy Advance"
        case .nes: "Nintendo Entertainment System"
        case .snes: "Super Nintendo Entertainment System"
        @unknown default: "Unknown System"
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
}

extension GameSystem: Codable {}

extension GameSystem: @retroactive CaseIterable {
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

extension GameCoreCheatFormat: @retroactive Equatable, @retroactive Hashable {
    public static func == (lhs: GameCoreCheatFormat, rhs: GameCoreCheatFormat) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension GameCoreCheatFormat {
    /// Normalize the code for storage or loading into the core
    func normalizeCode(string: String) -> String {
        let characterSet = self.characterSet.swiftCharacterSet.union(.onlyNewlineFeed)
        return string.normalize(with: characterSet)
    }

    func makeFormatter() -> CheatFormatter {
        let characterSet = self.characterSet.swiftCharacterSet
        return .init(format: format, characterSet: characterSet)
    }
}

// MARK: Conformances

extension GameCoreInfo: @retroactive @unchecked Sendable {}
