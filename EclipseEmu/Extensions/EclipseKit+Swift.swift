import Metal
import AVFoundation
import EclipseKit

extension GameSystem {
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
        @unknown default:
            "Unknown System"
        }
    }
}

extension GameCoreVideoPixelFormat {
    var metal: MTLPixelFormat? {
        return switch self {
        case .bgra8Unorm: .bgra8Unorm
        default: nil
        }
    }
}

extension GameCoreCommonAudioFormat {
    var avCommonFormat: AVAudioCommonFormat {
        return switch self {
        case .pcmFloat32:
            .pcmFormatFloat32
        case .pcmFloat64:
            .pcmFormatFloat64
        case .pcmInt16:
            .pcmFormatInt16
        case .pcmInt32:
            .pcmFormatInt32
        default:
            .otherFormat
        }
    }
}

extension GameCoreAudioFormat {
    var avAudioFormat: AVAudioFormat? {
        AVAudioFormat(commonFormat: self.commonFormat.avCommonFormat, sampleRate: self.sampleRate, channels: self.channelCount, interleaved: true)
    }
}
