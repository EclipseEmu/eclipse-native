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
            TagObject.create(in: objectContext, name: "Collection 0", color: .mint),
            TagObject.create(in: objectContext, name: "Collection 1", color: .cyan),
            TagObject.create(in: objectContext, name: "Collection 2", color: .green),
            TagObject.create(in: objectContext, name: "Collection 3", color: .blue),
        ]

        for i in 0..<32 {
            let game = GameObject.create(
                in: objectContext,
                name: "Game \(i)",
                system: .gba,
                sha1: "abcdef1234567890",
                romExtension: "gba",
                saveExtension: "sav"
            )

            let randIdx = i & 3
            tags[randIdx].addToGames(game)
            for j in (0...randIdx) {
                let saveState = SaveStateObject.create(
                    in: objectContext,
                    isAuto: j == 0,
					core: .testCore,
                    stateExtension: "s8"
                )
                saveState.game = game
            }
        }
    }

    func body(content: Content, context: Persistence) -> some View {
        content.persistence(context)
    }
}
