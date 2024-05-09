import Foundation

extension String {
    struct CharacterCounts {
        let inSet: Int
        let outsideSet: Int
    }
    
    static func normalize(_ string: String, with characterSet: CharacterSet) -> String {
        return string.trimmed().filter {
            $0.unicodeScalars.allSatisfy(characterSet.contains(_:))
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
    
    /// A version of trimmingCharacters(in:) that does not create a new string.
    func trimmed(in characterSet: CharacterSet = .whitespacesAndNewlines) -> SubSequence {
        guard self.startIndex != self.endIndex else {
            return self[self.startIndex..<self.endIndex]
        }
        
        // determine the start index
        var newStartIndex = self.startIndex
        while newStartIndex < self.endIndex {
            if !self[newStartIndex].unicodeScalars.allSatisfy(characterSet.contains(_:)) {
                break
            }
            newStartIndex = self.index(after: newStartIndex)
        }
        
        // determine the end index
        var newEndIndex = self.index(before: self.endIndex)
        while newEndIndex > self.startIndex {
            if !self[newEndIndex].unicodeScalars.allSatisfy(characterSet.contains(_:)) {
                break
            }
            newEndIndex = self.index(before: newEndIndex)
        }
        
        // ensure our bounds are correct
        guard newEndIndex != self.startIndex else {
            return self[self.startIndex..<self.index(after: self.startIndex)]
        }
        
        // return the slice
        return self[newStartIndex...newEndIndex]
    }
    
    func find(_ element: Element, after start: Index) -> Index? {
        var i = start
        while i < self.endIndex {
            if self[i] == element {
                return i
            }
            i = self.index(after: i)
        }
        return nil
    }
    
    func find(_ element: Element, before start: Index) -> Index? {
        var i = start
        while i > self.startIndex {
            if self[i] == element {
                return i
            }
            i = self.index(before: i)
        }
        return self[i] == element ? i : nil
    }
    
    func sameIndex(in source: Self, at sourceIndex: Index) -> Index {
        let distance = source.distance(from: source.startIndex, to: sourceIndex)
        return self.index(self.startIndex, offsetBy: distance)
    }
}
