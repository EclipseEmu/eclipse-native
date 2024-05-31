import SwiftUI

struct GameCollectionItem: View {
    @Environment(\.persistenceCoordinator) var persistence
    @ObservedObject var collection: GameCollection

    var body: some View {
        NavigationLink {
            GameCollectionView(collection: collection)
        } label: {
            VStack(alignment: .leading) {
                CollectionIconView(icon: collection.icon)
                    .aspectRatio(1.0, contentMode: .fit)
                    .fixedSize()
                    .frame(width: 32, height: 32)
                    .padding(.bottom, 8.0)

                Text(collection.name ?? "Unnamed Collection")
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .foregroundColor(.white)
            .padding()
            .backgroundGradient(color: collection.parsedColor.color)
            .clipShape(RoundedRectangle(cornerRadius: 16.0))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                CollectionManager.delete(collection, in: persistence)
            } label: {
                Label("Delete Collection", systemImage: "trash")
            }
        }
    }
}

#Preview {
    let context = PersistenceCoordinator.preview.container.viewContext
    let collection = GameCollection(context: context)
    collection.name = "Adventure"
    collection.icon = .symbol("tent.fill")
    collection.color = GameCollection.Color.indigo.rawValue

    return CompatNavigationStack {
        GameCollectionItem(collection: collection)
            .frame(width: 180.0)
    }
    .environment(\.managedObjectContext, context)
}
