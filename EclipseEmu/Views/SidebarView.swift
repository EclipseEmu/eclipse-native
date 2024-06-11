import SwiftUI

#if os(macOS)
struct SidebarView: View {
    enum Selection: Hashable {
        case library
        case collection(GameCollection)
    }

    @Environment(\.persistenceCoordinator) var persistence
    @Binding var selection: Self.Selection
    @State var isCreateCollectionOpen = false

    @FetchRequest<GameCollection>(sortDescriptors: [NSSortDescriptor(keyPath: \GameCollection.name, ascending: true)])
    var collections: FetchedResults<GameCollection>

    var body: some View {
        List(selection: $selection) {
            Section {
                Label("Library", systemImage: "books.vertical")
                    .tag(Selection.library)
            }

            Section("Collections") {
                ForEach(collections) { collection in
                    Label {
                        Text(verbatim: collection.name ?? "Collection")
                    } icon: {
                        CollectionIconView(icon: collection.icon)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            CollectionManager.delete(collection, in: persistence)
                        } label: {
                            Label("Delete Collection", systemImage: "trash")
                        }
                    }
                    .tag(Selection.collection(collection))
                }

                Button {
                    isCreateCollectionOpen = true
                } label: {
                    Label("Create Collection", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
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
#endif
