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

extension GameCoreCheatFormat: Hashable {
    public static func == (lhs: GameCoreCheatFormat, rhs: GameCoreCheatFormat) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension GameCoreCheatFormat {
    struct Formatter {
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
        
        func format(_ value: String) -> String {
            var formatIndex = formatString.startIndex
            let formatLastIndex = formatString.index(before: formatString.endIndex)
            var output: String = ""
            
            var i = value.startIndex
            while i < value.endIndex {
                if formatString[formatIndex] == "x" {
                    let ch = value[i]
                    i = value.index(after: i)
                    if !ch.unicodeScalars.allSatisfy(characterSet.contains(_:)) {
                        continue
                    }
                    output.append(ch.uppercased())
                } else {
                    output.append(formatString[formatIndex])
                }
                
                formatIndex = formatString.index(after: formatIndex)
                
                if formatIndex == formatLastIndex {
                    formatIndex = formatString.startIndex
                    output.append("\n" as Character)
                }
            }

            return output
        }
        
        func formatInput(value: String, range: Range<String.Index>, wasBackspace: Bool, insertionCount: Int) -> FormattedText {
            var formatIndex = formatString.startIndex
            let formatLastIndex = formatString.index(before: formatString.endIndex)
            var output: String = ""
            
            let cursorIndex = range.lowerBound
            let direction = Int(!wasBackspace)
            var offset = insertionCount
            
            var lastCharWasAddedAutomatically = false
            var i = value.startIndex
            while i < value.endIndex {
                if cursorIndex == i && lastCharWasAddedAutomatically && wasBackspace {
                    offset -= 1
                }
                
                if formatString[formatIndex] == "x" {
                    let ch = value[i]
                    i = value.index(after: i)
                    lastCharWasAddedAutomatically = false
                    if !ch.unicodeScalars.allSatisfy(characterSet.contains(_:)) {
                        continue
                    }
                    output.append(ch.uppercased())
                } else {
                    output.append(formatString[formatIndex])
                    
                    if cursorIndex == i {
                        offset += direction
                        print(offset)
                    }
                    lastCharWasAddedAutomatically = true
                }
                
                formatIndex = formatString.index(after: formatIndex)
                
                if formatIndex == formatLastIndex {
                    formatIndex = formatString.startIndex
                    output.append("\n" as Character)
                    
                    if cursorIndex == i {
                        offset += direction
                    }
                }
            }
            
            let newPosition = cursorIndex.utf16Offset(in: output) + offset
            let newIndex = if newPosition > output.utf16.count {
                output.index(before: output.endIndex)
            } else if newPosition < 0 {
                output.startIndex
            } else {
                output.index(cursorIndex, offsetBy: offset)
            }
            
            return .init(formattedText: output, cursorOffset: newIndex.utf16Offset(in: output))
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
