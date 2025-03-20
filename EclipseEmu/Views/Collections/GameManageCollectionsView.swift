import SwiftUI

struct GameManageCollectionItem: View {
    let collection: Tag
    let stateChanged: (Tag, Bool) -> Void
    @State var isSelected: Bool

    init(collection: Tag, isSelected: Bool, stateChanged: @escaping (Tag, Bool) -> Void) {
        self.collection = collection
        self.isSelected = isSelected
        self.stateChanged = stateChanged
    }

    var body: some View {
        HStack {
            Label {
                Text(collection.name ?? "Collection")
            } icon: {
                Image(systemName: "tag")
                    .foregroundStyle(collection.parsedColor.color)
                    .aspectRatio(1.0, contentMode: .fit)
                    .fixedSize()
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Toggle("", isOn: $isSelected).labelsHidden()
                .onChange(of: isSelected, perform: self.onChange(newState:))
        }
    }

    func onChange(newState: Bool) {
        self.stateChanged(self.collection, newState)
    }
}

struct GameManageCollectionsView: View {
    @ObservedObject var game: Game
    @EnvironmentObject var persistence: Persistence
    @Environment(\.dismiss) var dismiss
    @State var selectedCollections: Set<Tag>
    @State var isCreateCollectionOpen = false
    @FetchRequest<Tag>(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    var collections: FetchedResults<Tag>

    init(game: Game) {
        self.game = game
        self.selectedCollections = game.tags as? Set<Tag> ?? Set()
    }

    var body: some View {
        List {
            Section {
                ForEach(collections) { collection in
                    GameManageCollectionItem(
                        collection: collection,
                        isSelected: selectedCollections.contains(collection),
                        stateChanged: self.stateChanged(collection:newState:)
                    )
                }
            }
            Section {
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
        .navigationTitle("Manage Collections")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: self.finish) {
                    Text("Done")
                }
            }
        }
    }

    func stateChanged(collection: Tag, newState: Bool) {
        if newState {
            self.selectedCollections.insert(collection)
        } else {
            self.selectedCollections.remove(collection)
        }
    }

    func finish() {
        Task {
            do {
                try await persistence.library.setTags(selectedCollections.map { ObjectBox($0) }, for: .init(game))
            } catch {
                // FIXME: Surface error
                print(error)
            }
            self.dismiss()
        }
    }
}
