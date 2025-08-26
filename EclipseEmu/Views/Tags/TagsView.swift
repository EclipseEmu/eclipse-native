import SwiftUI

struct TagsView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @EnvironmentObject var persistence: Persistence
    @State var isCreateDialogPresented: Bool = false
	@State var editTarget: EditorTarget<TagObject>? = nil
    @State var renameItem: TagObject?

    @FetchRequest<TagObject>(sortDescriptors: [NSSortDescriptor(keyPath: \TagObject.name, ascending: true)])
    var tags: FetchedResults<TagObject>

    @ViewBuilder
    var mainContent: some View {
        if tags.isEmpty {
            ContentUnavailableMessage("NO_TAGS", systemImage: "tag", description: "NO_TAGS_MESSAGE")
        } else {
            List {
                ForEach(tags) { tag in
                    EditableContent(verbatim: tag.name, fallback: "TAG", systemImage: "tag") {
						self.editTarget = .edit(tag)
					}
                    .listItemTint(tag.color.color)
                }
                .onDelete(perform: delete)
            }
        }
    }

    var body: some View {
        mainContent
#if !os(macOS)
			.navigationBarTitleDisplayMode(.inline)
#endif
            .navigationTitle("TAGS")
            .toolbar {
				ToolbarItem(placement: .cancellationAction) {
                    CancelButton("DONE", action: dismiss.callAsFunction)
				}

                ToolbarItem {
					Button("CREATE_TAG", systemImage: "plus") {
						self.editTarget = .create
                    }
                }
            }
            .renameItem("RENAME_TAG", item: $renameItem)
			.sheet(item: $editTarget) { item in
                FormSheetView {
					TagEditorView(mode: item)
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
#Preview(traits: .previewStorage) {
    NavigationStack {
        TagsView()
    }
}
