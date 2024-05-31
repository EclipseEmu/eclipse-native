import SwiftUI

struct GameCollectionsView: View {
    @FetchRequest<GameCollection>(sortDescriptors: [NSSortDescriptor(keyPath: \GameCollection.name, ascending: true)])
    var collections: FetchedResults<GameCollection>

    @State var isCreateCollectionOpen = false
    @State var searchQuery = ""

    var body: some View {
        CompatNavigationStack {
            ScrollView {
                GameCollectionGrid(collections: collections)
                    .padding()
            }
            .emptyState(collections.isEmpty) {
                ContentUnavailableMessage {
                    Label("No Collections", systemImage: "square.stack.fill")
                } description: {
                    Text("You haven't created any collections yet.")
                }
            }
            .searchable(text: $searchQuery)
            .onChange(of: searchQuery) { newValue in
                collections.nsPredicate = newValue.isEmpty
                    ? nil
                    : NSPredicate(format: "name CONTAINS %@", newValue)
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem {
                    Button {
                        self.isCreateCollectionOpen = true
                    } label: {
                        Label("Create Collection", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isCreateCollectionOpen) {
                EditCollectionView()
#if os(macOS)
                    .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
#endif
            }
        }
    }
}

#Preview {
    GameCollectionsView()
        .environment(\.managedObjectContext, PersistenceCoordinator.preview.context)
        .environment(\.persistenceCoordinator, PersistenceCoordinator.preview)
}
