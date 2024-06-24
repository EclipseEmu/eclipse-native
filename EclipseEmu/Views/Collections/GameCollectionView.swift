import SwiftUI

struct GameCollectionView: View {
    static let sortDescriptors = [NSSortDescriptor(keyPath: \Game.name, ascending: true)]

    @Environment(\.dismiss) var dismiss
    @Environment(\.persistence) var persistence
    @State var selectedGame: Game?
    @State var isGamePickerPresented: Bool = false
    @State var searchQuery: String = ""
    @State var isEditCollectionOpen: Bool = false

    @ObservedObject var collection: GameCollection
    @ObservedObject var viewModel: GameListViewModel

    init(collection: GameCollection) {
        self.collection = collection
        self.viewModel = GameListViewModel(filter: .collection(collection))
    }

    var body: some View {
        ScrollView {
            GameList(viewModel: viewModel)
        }
        .emptyState(viewModel.isEmpty) {
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
                            let collection = Persistence.Object(object: self.collection)
                            self.dismiss()
                            Task {
                                do {
                                    try await persistence.delete(collection)
                                } catch {
                                    print("[error] failed to delete the collection", error)
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
            EditCollectionView(collection: self.collection)
            #if os(macOS)
                .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
            #endif
        }
    }
}

#Preview {
    let persistence = Persistence.preview
    let collection = GameCollection(context: persistence.viewContext)

    return CompatNavigationStack {
        GameCollectionView(collection: collection)
    }
    .environment(\.persistence, persistence)
    .environment(\.managedObjectContext, persistence.viewContext)
}
