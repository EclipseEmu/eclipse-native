import Foundation

struct LazySplitIterator<T: BidirectionalCollection> where T.Element: Equatable {
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

        let subsequence = self.inner[self.previousIndex..<next]
        self.previousIndex = next != self.inner.endIndex ? self.inner.index(after: next) : self.inner.endIndex
        return subsequence
    }
}
