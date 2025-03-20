import Foundation

extension String {
    struct CharacterCounts {
        let inSet: Int
        let outsideSet: Int
    }

    func normalize(with characterSet: CharacterSet) -> String {
        return self.trimmed().filter {
            characterSet.contains(character: $0)
        }
    }

    func countValidCharacters(in characterSet: CharacterSet) -> Int {
        var count = 0

        for scalar in self.unicodeScalars {
            count += Int(characterSet.contains(scalar))
        }

        return count
    }

    func countCharacters(in characterSet: CharacterSet) -> CharacterCounts {
        var inSet = 0
        var outsideSet = 0

        for scalar in self.unicodeScalars {
            let isInSet = Int(characterSet.contains(scalar))
            inSet += isInSet
            outsideSet += isInSet ^ 1
        }

        return .init(inSet: inSet, outsideSet: outsideSet)
    }

    /// A version of ``String.trimmingCharacters(in:)`` that does not create a new string.
    func trimmed(in characterSet: CharacterSet = .whitespacesAndNewlines) -> SubSequence {
        guard self.startIndex != self.endIndex else {
            return self[self.startIndex..<self.endIndex]
        }

        // determine the start index
        var newStartIndex = self.startIndex
        while newStartIndex < self.endIndex {
            if !characterSet.contains(character: self[newStartIndex]) {
                break
            }
            newStartIndex = self.index(after: newStartIndex)
        }

        // determine the end index
        var newEndIndex = self.index(before: self.endIndex)
        while newEndIndex > self.startIndex {
            if !characterSet.contains(character: self[newEndIndex]) {
                break
            }
            newEndIndex = self.index(before: newEndIndex)
        }

        // ensure our bounds are correct
        guard newEndIndex != self.startIndex else {
            return self[self.startIndex..<self.index(after: self.startIndex)]
        }

        // return the slice
        return self[newStartIndex ... newEndIndex]
    }

    @inlinable
    func leftPad(count: Int, with char: Character) -> String {
        String(repeating: char, count: count - self.count) + self
    }
}
