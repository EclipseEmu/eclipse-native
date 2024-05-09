import Foundation

extension CharacterSet {
    static let hexadecimal = CharacterSet(charactersIn: "abcdefABCDEF1234567890")
    static let onlyNewlineFeed = CharacterSet(charactersIn: "\n")
    
    @inlinable
    func contains(character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(self.contains(_:))
    }
}
