import SwiftUI

struct AddToCollectionView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @Environment(\.persistenceCoordinator) var persistence: PersistenceCoordinator

    @ObservedObject var viewModel: GameListViewModel
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \GameCollection.name, ascending: true)])
    var collections: FetchedResults<GameCollection>

    @State var isCreateCollectionOpen = false

    var body: some View {
        CompatNavigationStack {
            List {
                Section {
                    ForEach(collections) { collection in
                        Button {
                            viewModel.addSelectionToCollection(collection: collection, in: persistence)
                            dismiss()
                        } label: {
                            Label {
                                Text(verbatim: collection.name ?? "Collection")
                                    .foregroundStyle(Color.primary)
                            } icon: {
                                CollectionIconView(icon: collection.icon)
                                    .foregroundStyle(collection.parsedColor.color)
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .fixedSize()
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        self.isCreateCollectionOpen = true
                    } label: {
                        Label("New Collection", systemImage: "plus")
                    }
                }
            }
            .emptyState(collections.isEmpty) {
                ContentUnavailableMessage {
                    Label("No Collections", systemImage: "square.stack.fill")
                } description: {
                    Text("You haven't created any collections yet.")
                } actions: {
                    Button("Create Collection") {
                        self.isCreateCollectionOpen = true
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $isCreateCollectionOpen) {
                EditCollectionView()
#if os(macOS)
                    .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
#endif
            }
            .navigationTitle("Add to Collection")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let viewModel = GameListViewModel(filter: .none)
    return AddToCollectionView(viewModel: viewModel)
        .environment(\.persistenceCoordinator, PersistenceCoordinator.preview)
        .environment(\.managedObjectContext, PersistenceCoordinator.preview.context)
}
