import Foundation

class CheatFormatter {
    struct FormattedText {
        let formattedText: String
        let cursorOffset: Int
        
        static let zero = Self(formattedText: "", cursorOffset: 0)
    }
    
    private let formatString: String
    private let characterSet: CharacterSet

    init(format: UnsafePointer<CChar>, characterSet: CharacterSet) {
        self.formatString = String(cString: format)
        self.characterSet = characterSet
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
        guard !value.isEmpty else { return false }
        
        var splitIterator = LazySplitIterator(value, seperator: "\n")
        while let line = splitIterator.next() {
            guard line.count == formatString.count else { return false }
            
            var formatIndex = formatString.startIndex
            var lineIndex = line.startIndex
            while formatIndex < formatString.endIndex {
                let ch = line[lineIndex]
                let formatCh = formatString[formatIndex]
                let isPlaceholder = formatCh == "x"
                if isPlaceholder && !characterSet.contains(character: ch) || !isPlaceholder && ch != formatCh {
                    return false
                }
                
                formatIndex = formatString.index(after: formatIndex)
                lineIndex = line.index(after: lineIndex)
            }
        }
        
        return true
    }
}
