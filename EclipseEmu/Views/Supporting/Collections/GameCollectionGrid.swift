import SwiftUI

struct GameCollectionGrid<GameCollections: RandomAccessCollection>: View
    where GameCollections.Element == GameCollection {
    let collections: GameCollections

    var body: some View {
        LazyVGrid(
            columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)],
            spacing: 16.0
        ) {
            ForEach(collections) { collection in
                GameCollectionItem(collection: collection)
            }
        }
    }
}

#Preview {
    GameCollectionGrid(collections: [])
}
