import SwiftUI

struct PreviewStorage: PreviewModifier {
    static func makeSharedContext() throws(PersistenceError) -> Persistence {
        let persistence = Persistence(inMemory: true)
        insertGames(into: persistence)
        try persistence.mainContext.saveIfNeeded()
        return persistence
    }

    private static func insertGames(into persistence: Persistence) {
        let objectContext = persistence.mainContext

        let tags = [
            Tag(name: "Collection 0", color: .mint),
            Tag(name: "Collection 1", color: .cyan),
            Tag(name: "Collection 2", color: .green),
            Tag(name: "Collection 3", color: .blue),
        ]

        for tag in tags {
            objectContext.insert(tag)
        }

        for i in 0..<32 {
            let game = Game(
                name: "Game \(i)",
                system: .gba,
                sha1: "abcdef1234567890",
                romExtension: "gba",
                saveExtension: "sav",
                boxart: nil
            )
            objectContext.insert(game)

            let randIdx = i & 3
            tags[randIdx].addToGames(game)
            for j in (0...randIdx) {
                let saveState = SaveState(isAuto: j == 0, stateExtension: "s8", preview: nil, game: nil)
                objectContext.insert(saveState)
                saveState.game = game
            }
        }
    }

    func body(content: Content, context: Persistence) -> some View {
        content.persistence(context)
    }
}
