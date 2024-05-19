import SwiftUI

struct GameCollectionView: View {
    static let sortDescriptors = [NSSortDescriptor(keyPath: \Game.name, ascending: true)]
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.persistenceCoordinator) var persistence
    @FetchRequest<Game>(sortDescriptors: Self.sortDescriptors) var games
    @State var selectedGame: Game?
    @State var isGamePickerPresented: Bool = false
    @State var searchQuery: String = ""
    @State var isEditCollectionOpen: Bool = false
    
    @ObservedObject var collection: GameCollection

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
        .searchable(text: $searchQuery)
        .onChange(of: searchQuery) { newValue in
            games.nsPredicate = CollectionManager.searchPredicate(collection: collection, query: newValue)
        }
        .sheet(isPresented: $isGamePickerPresented) {
            GamePicker(collection: self.collection)
        }
        .sheet(item: $selectedGame) { game in
            GameView(game: game)
            #if os(macOS)
                .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
            #endif
        }
        .navigationTitle(self.collection.name ?? "Collection")
        .toolbar {
            ToolbarItem {
                Menu {
                    Button {
                        self.isEditCollectionOpen = true
                    } label: {
                        Label("Edit Info", systemImage: "rectangle.and.pencil.and.ellipsis")
                    }
                    
                    Button {
                        isGamePickerPresented = true
                    } label: {
                        Label("Manage Games", systemImage: "list.bullet")
                    }
                    
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
        .sheet(isPresented: $isEditCollectionOpen) {
            EditCollectionView(collection: self.collection)
            #if os(macOS)
                .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
            #endif
        }
    }
}
