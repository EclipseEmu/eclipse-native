import SwiftUI

struct TagsView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @EnvironmentObject var persistence: Persistence
	@State var editTarget: EditorTarget<TagObject>? = nil

    @FetchRequest<TagObject>(sortDescriptors: [NSSortDescriptor(keyPath: \TagObject.name, ascending: true)])
    var tags: FetchedResults<TagObject>

    var body: some View {
        content
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
			.sheet(item: $editTarget) { item in
                FormSheetView {
					TagEditorView(mode: item)
				}
			}
    }
    
    @ViewBuilder
    var content: some View {
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


    func delete(_ indicies: IndexSet) {
        let items = indicies.map { ObjectBox(tags[$0]) }
        Task {
            do {
                try await persistence.objects.deleteMany(items)
            } catch {
                // FIXME: Surface error
                print(error)
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
