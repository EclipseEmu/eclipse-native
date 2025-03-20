import SwiftUI

struct PreviewStorage: PreviewModifier {
    static func makeSharedContext() throws -> Persistence {
        let persistence = Persistence(inMemory: true)
        try insertGames(into: persistence)
        try persistence.mainContext.saveIfNeeded()
        return persistence
    }

    static func insertGames(into persistence: Persistence) throws {
        let ctx = persistence.mainContext

        let tags = [
            Tag(name: "Collection 0", color: .mint),
            Tag(name: "Collection 1", color: .cyan),
            Tag(name: "Collection 2", color: .green),
            Tag(name: "Collection 3", color: .blue),
        ]

        for tag in tags {
            ctx.insert(tag)
        }

        for i in 0..<32 {
            let game = Game(
                name: "Game \(i)",
                system: .gba,
                md5: "abcdef1234567890",
                romExtension: "gba",
                saveExtension: "sav",
                boxart: nil
            )
            ctx.insert(game)

            let randIdx = i & 3
            tags[randIdx].addToGames(game)
            for j in (0...randIdx) {
                let saveState = SaveState(isAuto: j == 0, stateExtension: "s8", preview: nil, game: game)
                ctx.insert(saveState)
            }
        }
    }

    func body(content: Content, context: Persistence) -> some View {
        content.persistence(context)
    }
}
