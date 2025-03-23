import SwiftUI

private struct TagSelectionView: View {
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

struct GameTagsView: View {
    @ObservedObject var game: Game
    @EnvironmentObject var persistence: Persistence
    @Environment(\.dismiss) var dismiss
    @State var selection: Set<Tag>
    @State var isCreateTagOpen = false
    @FetchRequest<Tag>(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    var collections: FetchedResults<Tag>

    init(game: Game) {
        self.game = game
        self.selection = game.tags as? Set<Tag> ?? Set()
    }

    var body: some View {
        List {
            Section {
                ForEach(collections) { collection in
                    TagSelectionView(
                        collection: collection,
                        isSelected: selection.contains(collection),
                        stateChanged: stateChanged
                    )
                }
            }
            Section {
                Button {
                    self.isCreateTagOpen = true
                } label: {
                    Label("Create Tag", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreateTagOpen) {
            EditTagView()
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
                Button("Done", action: self.finish)
            }
        }
    }

    private func stateChanged(collection: Tag, newState: Bool) {
        if newState {
            selection.insert(collection)
        } else {
            selection.remove(collection)
        }
    }

    private func finish() {
        Task {
            do {
                try await persistence.objects.setTags(selection.map { ObjectBox($0) }, for: .init(game))
            } catch {
                // FIXME: Surface error
                print(error)
            }
            self.dismiss()
        }
    }
}
