import SwiftUI

private extension EditorTarget where Item == TagObject {
    var title: LocalizedStringKey {
        switch self {
        case .create: "CREATE_TAG"
        case .edit: "EDIT_TAG"
        }
    }

    var confirmationButton: LocalizedStringKey {
        switch self {
        case .create: "CREATE"
        case .edit: "SAVE"
        }
    }
}

struct TagDetailView: View {
    @Environment(\.dismiss) private var dismissAction: DismissAction
    @EnvironmentObject private var persistence: Persistence

    private let mode: EditorTarget<TagObject>

    @State private var newName: String
    @State private var newColor: TagColor

    init(mode: EditorTarget<TagObject>) {
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
                    Text("TAG_NAME")
                }
            } header: {
                Text("NAME")
            }

            Section {
                FixedColorPicker(selection: $newColor)
                    .listRowInsets(EdgeInsets())
            } header: {
                Text("COLOR")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(mode.title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
			ToolbarItem(placement: .cancellationAction) {
				DismissButton("CANCEL")
            }

            ToolbarItem(placement: .confirmationAction) {
				ConfirmButton(mode.confirmationButton, action: handleSave)
            }
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
