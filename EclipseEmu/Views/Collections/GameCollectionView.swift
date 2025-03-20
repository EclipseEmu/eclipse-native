import SwiftUI

struct GameCollectionView: View {
    static let sortDescriptors = [NSSortDescriptor(keyPath: \Game.name, ascending: true)]

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: Persistence
    @FetchRequest<Game>(sortDescriptors: Self.sortDescriptors) var games
    @State var selectedGame: Game?
    @State var isGamePickerPresented: Bool = false
    @State var searchQuery: String = ""
    @State var isEditCollectionOpen: Bool = false

    @ObservedObject var collection: Tag
    @ObservedObject var viewModel: GameListViewModel

    init(collection: Tag) {
        self.collection = collection
        self.viewModel = GameListViewModel(filter: .tag(collection))

        let request = Game.fetchRequest()
        request.predicate = NSPredicate(format: "%K CONTAINS %@", #keyPath(Game.tags), collection)
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
        .searchable(text: self.$viewModel.searchQuery)
        #if os(macOS)
        .navigationTitle("Collection")
        .navigationSubtitle(collection.name ?? "Collection")
        #else
        .navigationTitle(collection.name ?? "Collection")
        #endif
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
                            Task {
                                do {
                                    try await persistence.library.delete(.init(collection))
                                } catch {
                                    // FIXME: Surface error
                                    print(error)
                                }
                            }
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
            EditCollectionView(tag: self.collection)
            #if os(macOS)
                .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
            #endif
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Tag.fetchRequest()) { tag, _ in
        NavigationStack {
            GameCollectionView(collection: tag)
        }
    }
}
