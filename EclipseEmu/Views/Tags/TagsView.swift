import SwiftUI

struct TagsView: View {
    @EnvironmentObject var persistence: Persistence
    @EnvironmentObject var navigationManager: NavigationManager
    @State var isCreateDialogPresented: Bool = false
    @State var renameItem: TagObject?

    @FetchRequest<TagObject>(sortDescriptors: [NSSortDescriptor(keyPath: \TagObject.name, ascending: true)])
    var tags: FetchedResults<TagObject>

    @ViewBuilder
    var mainContent: some View {
        if tags.isEmpty {
            ContentUnavailableMessage {
                Label("NO_TAGS", systemImage: "tag")
            } description: {
                Text("NO_TAGS_MESSAGE")
            }
        } else {
            List {
                ForEach(tags) { tag in
                    NavigationLink(to: .editTag(tag)) {
                        Label(tag.name ?? "TAG", systemImage: "tag")
                    }
                    .listItemTint(tag.color.color)
                }
                .onDelete(perform: delete)
            }
        }
    }

    var body: some View {
        mainContent
            .navigationTitle("TAGS")
            .toolbar {
                #if !os(macOS)
                ToolbarItem {
                    EditButton()
                }
                #endif
                ToolbarItem {
                    ToggleButton(value: $isCreateDialogPresented) {
                        Label("CREATE_TAG", systemImage: "plus")
                    }
                }
            }
            .renameItem("RENAME_TAG", item: $renameItem)
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
