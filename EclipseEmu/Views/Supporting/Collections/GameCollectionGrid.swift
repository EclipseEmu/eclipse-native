import SwiftUI

struct GameCollectionGrid<Tags: RandomAccessCollection>: View where
    Tags.Element == Tag
{
    let collections: Tags

    var body: some View {
        LazyVGrid(
            columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)],
            spacing: 16.0
        ) {
            ForEach(collections) { tag in
                GameCollectionItem(collection: tag)
            }
        }
    }
}

#Preview {
    GameCollectionGrid(collections: [])
}
