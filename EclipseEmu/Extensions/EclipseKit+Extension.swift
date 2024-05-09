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
        AVAudioFormat(commonFormat: self.commonFormat.avCommonFormat, sampleRate: self.sampleRate, channels: self.channelCount, interleaved: true)
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

extension GameCoreCheatFormat: Equatable, Hashable {
    public static func == (lhs: GameCoreCheatFormat, rhs: GameCoreCheatFormat) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension GameCoreCheatFormat {
    class Formatter {
        struct FormattedText {
            let formattedText: String
            let cursorOffset: Int
            
            static let zero = Self(formattedText: "", cursorOffset: 0)
        }
        
        private let formatString: String
        let characterSet: CharacterSet
        private let characterSetAndNewline: CharacterSet

        init(format: UnsafePointer<CChar>, characterSet: CharacterSet) {
            self.formatString = String(cString: format)
            self.characterSet = characterSet
            self.characterSetAndNewline = characterSet.union(.onlyNewlineFeed)
        }
        
        @inlinable
        func formatInput(value: String) -> String {
            return self.formatInput(value: value, range: value.startIndex..<value.startIndex, wasBackspace: false, insertion: "").formattedText
        }
        
        func formatInput(value: String, range: Range<String.Index>, wasBackspace: Bool, insertion: String) -> FormattedText {
            let isBackspace = Int(wasBackspace)
            let isNotBackspace = isBackspace ^ 1
            let cursorIndex = range.lowerBound
            
            var output: String = ""
            var offset = insertion.countValidCharacters(in: self.characterSet)
            var valueIndex = value.startIndex
            var formatIndex = formatString.startIndex
            
            var wasLastCharAutomaticallyInserted = 0
            while valueIndex < value.endIndex {
                let isCursorHere = Int(cursorIndex == valueIndex)
                let shouldBumpOffset = isCursorHere & isNotBackspace
                offset -= (isNotBackspace ^ 1) & wasLastCharAutomaticallyInserted & isCursorHere
                
                if formatIndex == formatString.endIndex {
                    formatIndex = formatString.startIndex
                    output.append("\n" as Character)
                    offset += shouldBumpOffset
                }
                
                if formatString[formatIndex] != "x" {
                    output.append(formatString[formatIndex])
                    offset += shouldBumpOffset
                    wasLastCharAutomaticallyInserted = 1
                } else {
                    let ch = value[valueIndex]
                    valueIndex = value.index(after: valueIndex)
                    guard characterSet.contains(character: ch) else { continue }
                    output.append(ch.uppercased())
                    wasLastCharAutomaticallyInserted = 0
                }
                
                formatIndex = formatString.index(after: formatIndex)
            }
            
            let isCursorHere = Int(cursorIndex == valueIndex)
            offset -= isCursorHere & isBackspace & wasLastCharAutomaticallyInserted
            
            let newPosition = cursorIndex.utf16Offset(in: output) + offset
            let newIndex = if newPosition > output.utf16.count {
                output.index(before: output.endIndex)
            } else if newPosition < 0 {
                output.startIndex
            } else {
                output.index(cursorIndex, offsetBy: offset)
            }
            
            return FormattedText(
                formattedText: output,
                cursorOffset: newIndex.utf16Offset(in: output)
            )
        }
        
        func validate(value: String) -> Bool {
            return false
        }
    }
    
    /// Normalize the code for storage or loading into the core
    func normalizeCode(string: String) -> String {
        let characterSet = self.characterSet.swiftCharacterSet.union(.onlyNewlineFeed)
        return String.normalize(string, with: characterSet)
    }
    
    func makeFormatter() -> Formatter {
        let characterSet = self.characterSet.swiftCharacterSet
        return .init(format: format, characterSet: characterSet)
    }
}
