import Foundation

extension Set {
    @inlinable
    mutating func toggle(_ member: Element, if state: Bool) {
        if state {
            self.insert(member)
        } else {
            self.remove(member)
        }
    }
}
