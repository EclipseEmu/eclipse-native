import EclipseKit

/// The definition of a cheat format. This struct is a Swift-safe version of the `GameCoreCheatFormat` struct.
struct CheatFormat: Identifiable, Equatable, Hashable {
    /// A unique ID for this cheat format.
    let id: String
    /// The user-shown name of this cheat format.
    let displayName: String
    /// A string of allowed characters, i.e. "ABXYabxy" to allow both upper and lower case a, b, x, and y.
    let characterSet: GameCoreCheatCharacterSet
    /// The user-shown name of this cheat format.
    let format: String

    init(raw: GameCoreCheatFormat) {
        self.id = String(cString: raw.id)
        self.displayName = String(cString: raw.displayName)
        self.characterSet = raw.characterSet
        self.format = String(cString: raw.format)
    }

    public static func == (lhs: CheatFormat, rhs: CheatFormat) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    /// Normalize the code for storage or loading into the core
    func normalizeCode(string: String) -> String {
        let characterSet = self.characterSet.swiftCharacterSet.union(.onlyNewlineFeed)
        return string.normalize(with: characterSet)
    }

    /// Make a formatter for this cheat format
    func makeFormatter() -> CheatFormatter {
        let characterSet = self.characterSet.swiftCharacterSet
        return .init(format: format, characterSet: characterSet)
    }
}
