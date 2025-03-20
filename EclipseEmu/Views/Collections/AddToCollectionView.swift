import SwiftUI

struct AddToCollectionView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @EnvironmentObject var persistence: Persistence

    @ObservedObject var viewModel: GameListViewModel
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    var collections: FetchedResults<Tag>

    @State var isCreateCollectionOpen = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(collections) { collection in
                        Button {
                            // FIXME: Re-enable
                            //                            viewModel.addSelectionToCollection(collection: collection, in: persistence)
                            dismiss()
                        } label: {
                            Label {
                                Text(verbatim: collection.name ?? "Collection")
                                    .foregroundStyle(Color.primary)
                            } icon: {
                                Image(systemName: "tag")
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
                    .buttonStyle(.borderedProminent)
                    #if !os(macOS)
                        .buttonBorderShape(.capsule)
                    #endif
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

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    AddToCollectionView(viewModel: GameListViewModel(filter: .none))
}
