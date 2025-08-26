import SwiftUI
import AVFoundation
import EclipseKit
import Metal


// MARK: System

extension System: @retroactive Codable {
    var string: String {
        return switch self {
        case .unknown: String(localized: "SYSTEM_UNKNOWN")
        case .gb: String(localized: "SYSTEM_GB")
        case .gbc: String(localized: "SYSTEM_GBC")
        case .gba: String(localized: "SYSTEM_GBA")
        case .nes: String(localized: "SYSTEM_NES")
        case .snes: String(localized: "SYSTEM_SNES")
        @unknown default: String(localized: "SYSTEM_UNKNOWN")
        }
    }

	static let concreteCases: [Self] = [.gb, .gbc, .gba, .nes, .snes]

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

    var inputs: CoreInput {
        switch self {
		case .unknown: []
        case .gb, .gbc, .nes:
			[.dpad, .faceButtonRight, .faceButtonDown, .start, .select]
        case .gba:
			[.dpad, .faceButtonRight, .faceButtonDown, .start, .select, .leftShoulder, .rightShoulder]
        case .snes:
			[.dpad, .faceButtonUp, .faceButtonLeft, .faceButtonRight, .faceButtonDown, .start, .select, .leftShoulder, .rightShoulder]
        @unknown default:
            []
        }
    }

	var controlNamingConvention: ControlNamingConvention {
		switch self {
		case .gb, .gba, .gbc, .nes, .snes, .unknown: .nintendo
		}
	}
}

// MARK: Audio

extension CoreAudioDescriptor {
	func getAudioFormat() -> AVAudioFormat? {
		let commonFormat: AVAudioCommonFormat = switch self.sampleFormat {
		case .float32: .pcmFormatFloat32
		case .float64: .pcmFormatFloat64
		case .int16: .pcmFormatInt16
		case .int32: .pcmFormatInt32
		}

		return AVAudioFormat(
			commonFormat: commonFormat,
			sampleRate: self.sampleRate,
			channels: UInt32(self.channelCount),
			interleaved: self.interlaced
		)
	}
}


// MARK: Cheats

extension CoreCheatFormat.CharacterSet {
    var swiftCharacterSet: CharacterSet {
        switch self {
        case .hexadecimal: .hexadecimal
        @unknown default: .hexadecimal
        }
    }
}

extension CoreCheat {
	init?(_ cheat: CheatObject) {
		guard let format = cheat.type, let code = cheat.code else { return nil }
		self = CoreCheat(format: format, code: code)
	}
}

extension CoreCheatFormat: @retroactive Equatable, @retroactive Hashable {
	public static func == (lhs: CoreCheatFormat, rhs: CoreCheatFormat) -> Bool {
		return lhs.id == rhs.id
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}

	/// Normalize the code for storage or loading into the core
	func normalizeCode(string: String) -> String {
		let characterSet = self.charset.swiftCharacterSet.union(.onlyNewlineFeed)
		return string.normalize(with: characterSet)
	}

	/// Make a formatter for this cheat format
	func makeFormatter() -> CheatFormatter {
		let characterSet = self.charset.swiftCharacterSet
		return .init(format: pattern, characterSet: characterSet)
	}
}


// MARK: Controls

extension CoreInput: @retroactive RandomAccessCollection {
	public typealias Index = Int

	@inlinable
	public var isEmpty: Bool { self.rawValue == 0 }

	@inlinable
	public var startIndex: Index { 0 }

	@inlinable
	public var endIndex: Index { rawValue.nonzeroBitCount }

	@inlinable
	public func index(after i: Index) -> Index { i + 1 }

	@inlinable
	public func index(before i: Index) -> Index { i - 1 }

	public subscript(position: Index) -> Self {
		precondition(position >= startIndex && position < endIndex, "oob")
		var value = rawValue
		for _ in 0..<position {
			value &= value - 1
		}
		return Self(rawValue: 1 << value.trailingZeroBitCount)
	}
}

extension CoreInput {
	static func inputs(for system: System) -> Self {
		let baseNintendo: Self = [.dpad, .faceButtonRight, .faceButtonDown, .start, .select]
		let gbaNintendo: Self = [baseNintendo, .leftShoulder, .rightShoulder]
		return switch system {
		case .gb, .gbc, .nes: baseNintendo
		case .gba: gbaNintendo
		case .snes: [gbaNintendo, .faceButtonUp, .faceButtonLeft]
		case .unknown: []
		}
	}

	static func directionalInputs(for system: System) -> Self {
		return switch system {
		case .gb, .gbc, .nes, .gba, .snes: .dpad
		case .unknown: []
		}
	}
}


