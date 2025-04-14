import SwiftUI

enum TagDetailViewMode: Hashable, Equatable {
    case edit(TagObject)
    case create

    var title: LocalizedStringKey {
        switch self {
        case .create: "Create Tag"
        case .edit: "Edit Tag"
        }
    }

    var confirmationButton: LocalizedStringKey {
        switch self {
        case .create: "Create"
        case .edit: "Save"
        }
    }
}

struct TagDetailView: View {
    @Environment(\.dismiss) private var dismissAction: DismissAction
    @EnvironmentObject private var persistence: Persistence

    private let mode: TagDetailViewMode

    @State private var newName: String
    @State private var newColor: TagColor
    @State private var deleteTag: TagObject?

    init(mode: TagDetailViewMode) {
        self.mode = mode
        if case .edit(let tag) = mode {
            newName = tag.name ?? ""
            newColor = tag.color
        } else {
            newName = ""
            newColor = .blue
        }
    }

    var body: some View {
        Form {
            Section {
                TextField(text: $newName) {
                    Text("Tag Name")
                }
            } header: {
                Text("Name")
            }

            Section {
                FixedColorPicker(selection: $newColor)
                    .listRowInsets(EdgeInsets())
            } header: {
                Text("Color")
            }

            if case .edit(let tag) = mode {
                Section {
                    Button("Delete Tag", role: .destructive) {
                        self.deleteTag = tag
                    }
                }
            }
        }
        .navigationTitle(mode.title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if mode == .create {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismissAction.callAsFunction)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(mode.confirmationButton, action: handleSave)
            }
        }
        .deleteItem("DELETE_TAG_TITLE", item: $deleteTag, dismiss: true) { tag in
            Text("DELETE_TAG_MESSAGE \(tag)")
        }
    }

    func handleSave() {
        if case .edit(let tag) = mode {
            let box = ObjectBox(tag)
            Task {
                do {
                    try await persistence.objects.update(tag: box, name: newName, color: newColor)
                    dismissAction()
                } catch {
                    // FIXME: Surface error
                    print(error)
                }
            }
        } else {
            Task {
                do {
                    try await persistence.objects.createTag(name: newName, color: newColor)
                    dismissAction()
                } catch {
                    // FIXME: Surface error
                    print(error)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TagDetailView(mode: .create)
    }
}
