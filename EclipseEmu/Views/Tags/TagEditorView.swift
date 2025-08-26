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

struct TagEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
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
            Section("NAME") {
                TextField(text: $newName) {
                    Text("TAG_NAME")
                }
            }

            Section("COLOR", content: colorPicker)
        }
        .formStyle(.grouped)
        .navigationTitle(mode.title)
        .toolbar {
			ToolbarItem(placement: .cancellationAction) {
                CancelButton("CANCEL", action: dismiss.callAsFunction)
            }

            ToolbarItem(placement: .confirmationAction) {
				ConfirmButton(mode.confirmationButton, action: handleSave)
            }
        }
    }
    
    @ViewBuilder
    private func colorPicker() -> some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: 36, maximum: 48), spacing: 16.0)], spacing: 16.0) {
            ForEach(TagColor.allCases, id: \.self) { color in
                Button {
                    withAnimation {
                        newColor = color
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 2)
                            .opacity(newColor == color ? 1.0 : 0.0)
                        Circle()
                            .padding(newColor == color ? 3.0 : 0.0)
                    }
                    .foregroundStyle(color.color)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    func handleSave() {
        if case .edit(let tag) = mode {
            let box = ObjectBox(tag)
            Task {
                do {
                    try await persistence.objects.update(tag: box, name: newName, color: newColor)
                    dismiss()
                } catch {
                    // FIXME: Surface error
                    print(error)
                }
            }
        } else {
            Task {
                do {
                    try await persistence.objects.createTag(name: newName, color: newColor)
                    dismiss()
                } catch {
                    // FIXME: Surface error
                    print(error)
                }
            }
        }
    }
}

#Preview {
    FormSheetView {
        TagEditorView(mode: .create)
    }
}
