extension Array where Element: Comparable {
	@inlinable
	@discardableResult
	public mutating func sortedInsert(_ newElement: Element) -> Int {
		let index = sortedIndex(for: newElement)
		self.insert(newElement, at: index)
		return index
	}

	public borrowing func sortedIndex(for value: Element) -> Int {
		var low = 0
		var high = self.count

		while low < high {
			let mid = (low + high) >> 1
			if self[mid] < value {
				low = mid + 1
			} else {
				high = mid
			}
		}

		return low
	}
}
