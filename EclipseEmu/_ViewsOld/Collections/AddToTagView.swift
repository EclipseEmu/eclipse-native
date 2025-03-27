import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct AddToTagView: View {
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
                                Text(verbatim: collection.name ?? "Tag")
                                    .foregroundStyle(Color.primary)
                            } icon: {
                                Image(systemName: "tag")
                                    .foregroundStyle(collection.color.color)
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
                        Label("New Tag", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isCreateCollectionOpen) {
                EditTagView()
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
                        Button("Done", action: dismiss)
                    }
                }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    AddToTagView(viewModel: GameListViewModel(filter: .none))
}
