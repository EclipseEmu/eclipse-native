import SwiftUI

struct TagsView: View {
    @EnvironmentObject var persistence: Persistence
    @EnvironmentObject var navigationManager: NavigationManager
    @State var isCreateDialogPresented: Bool = false
    @State var renameItem: Tag?

    @FetchRequest<Tag>(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    var tags: FetchedResults<Tag>

    @ViewBuilder
    var mainContent: some View {
        if tags.isEmpty {
            ContentUnavailableMessage {
                Label("No Tags", systemImage: "tag")
            } description: {
                Text("You haven't created any tags to organize your games yet.")
            }
        } else {
            List {
                ForEach(tags) { tag in
                    NavigationLink(to: .editTag(tag)) {
                        Label(tag.name ?? "Tag", systemImage: "tag")
                    }
                    .listItemTint(tag.color.color)
                }
                .onDelete(perform: delete)
            }
        }
    }

    var body: some View {
        mainContent
            .navigationTitle("Tags")
            .toolbar {
                #if !os(macOS)
                ToolbarItem {
                    EditButton()
                }
                #endif
                ToolbarItem {
                    ToggleButton(value: $isCreateDialogPresented) {
                        Label("Create Tag", systemImage: "plus")
                    }
                }
            }
            .renameItem("Rename Tag", item: $renameItem)
            .sheet(isPresented: $isCreateDialogPresented) {
                NavigationStack {
                    TagDetailView(mode: .create)
                }
            }
    }

    func delete(_ indicies: IndexSet) {
        let items = indicies.map { ObjectBox(tags[$0]) }
        Task {
            do {
                try await persistence.objects.deleteMany(items)
            } catch {
                // FIXME: Surface error
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    NavigationStack {
        TagsView()
    }
}
