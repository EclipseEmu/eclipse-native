import SwiftUI

struct GameCollectionView: View {
    static let sortDescriptors = [NSSortDescriptor(keyPath: \Game.name, ascending: true)]
    let collection: GameCollection
    
    @FetchRequest<Game>(sortDescriptors: Self.sortDescriptors) var games
    @State var selectedGame: Game?
    @Environment(\.dismiss) var dismiss
    @Environment(\.persistenceCoordinator) var persistence
    
    init(collection: GameCollection) {
        self.collection = collection
        let request = CollectionManager.listRequest(collection: collection)
        request.sortDescriptors = Self.sortDescriptors
        self._games = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        ScrollView {
            GameGrid(games: games, selectedGame: $selectedGame)
                .padding()
                .emptyMessage(self.games.isEmpty) {
                    Text("Empty Collection")
                } message: {
                    Text("You haven't added any games to this collection.")
                }
        }
        .navigationTitle(self.collection.name ?? "Collection")
        .toolbar {
            ToolbarItem {
                Menu {
                    Button(role: .destructive) {
                        let collection = self.collection
                        self.dismiss()
                        CollectionManager.delete(collection, in: persistence)
                    } label: {
                        Label("Delete Collection", systemImage: "trash")
                    }
                } label: {
                    Label("Menu", systemImage: "ellipsis.circle")
                }
            }
        }
    }
}
