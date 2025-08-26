import Foundation

struct CheatFormatter {
    struct FormattedText {
        static let zero = Self(formattedText: "", cursorOffset: 0)

        let formattedText: String
        let cursorOffset: Int
    }

    private let formatString: String
    private let characterSet: CharacterSet

    init(format: String, characterSet: CharacterSet) {
        self.formatString = format
        self.characterSet = characterSet
    }

    @inlinable
    func formatInput(value: String) -> String {
        return formatInput(
            value: value,
            range: value.startIndex ..< value.startIndex,
            wasBackspace: false,
            insertion: ""
        ).formattedText
    }

    func formatInput(
        value: String,
        range: Range<String.Index>,
        wasBackspace: Bool,
        insertion: String
    ) -> FormattedText {
        let isBackspace = Int(wasBackspace)
        let isNotBackspace = isBackspace ^ 1
        let cursorIndex = range.lowerBound

        var output = ""
        var offset = insertion.countValidCharacters(in: characterSet)
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
                let char = value[valueIndex]
                valueIndex = value.index(after: valueIndex)
                guard characterSet.contains(character: char) else { continue }
                output.append(char.uppercased())
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
                let char = line[lineIndex]
                let formatCh = formatString[formatIndex]
                let isPlaceholder = formatCh == "x"
                if isPlaceholder && !characterSet.contains(character: char) || !isPlaceholder && char != formatCh {
                    return false
                }

                formatIndex = formatString.index(after: formatIndex)
                lineIndex = line.index(after: lineIndex)
            }
        }

        return true
    }
}

private struct LazySplitIterator<T: BidirectionalCollection> where T.Element: Equatable {
    private let inner: T
    private let seperator: T.Element
    private var previousIndex: T.Index

    init(_ inner: T, seperator: T.Element) {
        self.inner = inner
        self.previousIndex = inner.startIndex
        self.seperator = seperator
    }

    mutating func next() -> T.SubSequence? {
        guard self.previousIndex != self.inner.endIndex else { return nil }

        var next = self.previousIndex
        while next < self.inner.endIndex {
            if self.inner[next] == self.seperator {
                break
            }
            next = self.inner.index(after: next)
        }

        let subsequence = self.inner[self.previousIndex ..< next]
        self.previousIndex = next != self.inner.endIndex ? self.inner.index(after: next) : self.inner.endIndex
        return subsequence
    }
}
