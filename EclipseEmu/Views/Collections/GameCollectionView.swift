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
    @ObservedObject var viewModel: GameListViewModel

    init(collection: GameCollection) {
        self.collection = collection
        self.viewModel = GameListViewModel(filter: .collection(collection))

        let request = CollectionManager.listRequest(collection: collection)
        request.sortDescriptors = Self.sortDescriptors
        self._games = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        ScrollView {
            GameList(viewModel: viewModel)
        }
        .emptyState(games.isEmpty) {
            ContentUnavailableMessage {
                Label("Empty Collection", systemImage: "square.stack.fill")
            } description: {
                Text("You haven't added any games to this collection.")
            }
        }
        .sheet(isPresented: $isGamePickerPresented) {
            GamePicker(collection: self.collection)
        }
        .sheet(item: $viewModel.target) { game in
            GameView(game: game)
            #if os(macOS)
                .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
            #endif
        }
        .navigationTitle(self.collection.name ?? "Collection")
        .toolbar {
            ToolbarItem {
                if !viewModel.isSelecting {
                    Menu {
                        Button {
                            self.isEditCollectionOpen = true
                        } label: {
                            Label("Edit Info", systemImage: "rectangle.and.pencil.and.ellipsis")
                        }

                        Button {
                            self.isGamePickerPresented = true
                        } label: {
                            Label("Manage Games", systemImage: "text.badge.plus")
                        }

                        Divider()

                        GameListMenuItems(viewModel: viewModel)

                        Divider()

                        Button(role: .destructive) {
                            let collection = self.collection
                            self.dismiss()
                            CollectionManager.delete(collection, in: persistence)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }

            #if !os(macOS)
            GameListToolbarItems(viewModel: viewModel)
            #endif
        }
        .sheet(isPresented: $isEditCollectionOpen) {
            EditCollectionView(collection: self.collection)
            #if os(macOS)
                .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
            #endif
        }
    }
}

#Preview {
    let persistence = PersistenceCoordinator.preview
    let collection = GameCollection(context: persistence.context)

    return CompatNavigationStack {
        GameCollectionView(collection: collection)
    }
    .environment(\.persistenceCoordinator, persistence)
    .environment(\.managedObjectContext, persistence.context)
}
