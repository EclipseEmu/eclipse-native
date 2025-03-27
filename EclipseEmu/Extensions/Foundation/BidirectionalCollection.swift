extension BidirectionalCollection where Element: Equatable {
    func splitOnce(separator: Element) -> (front: Self.SubSequence, back: Self.SubSequence?) {
        if let index = self.firstIndex(of: separator) {
            (self[..<index], self[index...])
        } else {
            (self[...], nil)
        }
    }
}
