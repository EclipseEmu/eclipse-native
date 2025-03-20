import SwiftUI

struct GameCollectionsView: View {
    @FetchRequest<Tag>(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    var collections: FetchedResults<Tag>

    @State var isCreateCollectionOpen = false
    @State var searchQuery = ""

    var body: some View {
        NavigationStack {
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

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    GameCollectionsView()
}
