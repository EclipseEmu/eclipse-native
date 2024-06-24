import SwiftUI

struct GameManageCollectionItem: View {
    let collection: GameCollection
    let stateChanged: (GameCollection, Bool) -> Void
    @State var isSelected: Bool
    @Environment(\.persistence) var persistence

    init(collection: GameCollection, isSelected: Bool, stateChanged: @escaping (GameCollection, Bool) -> Void) {
        self.collection = collection
        self.isSelected = isSelected
        self.stateChanged = stateChanged
    }

    var body: some View {
        HStack {
            Label {
                Text(collection.name ?? "Collection")
            } icon: {
                CollectionIconView(icon: collection.icon)
                    .foregroundStyle(collection.color)
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
    @Environment(\.persistence) var persistence
    @Environment(\.dismiss) var dismiss
    @State var selectedCollections: Set<GameCollection>
    @State var isCreateCollectionOpen = false
    @FetchRequest<GameCollection>(sortDescriptors: [NSSortDescriptor(keyPath: \GameCollection.name, ascending: true)])
    var collections: FetchedResults<GameCollection>

    init(game: Game) {
        self.game = game
        self.selectedCollections = game.collections as? Set<GameCollection> ?? Set()
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

    func stateChanged(collection: GameCollection, newState: Bool) {
        if newState {
            self.selectedCollections.insert(collection)
        } else {
            self.selectedCollections.remove(collection)
        }
    }

    func finish() {
        do {
            game.collections = selectedCollections as NSSet
            try persistence.save(in: persistence.viewContext)
        } catch {
            print("[error] error while saving games")
        }
        self.dismiss()
    }
}
