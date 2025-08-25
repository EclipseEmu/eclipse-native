import SwiftUI

enum SaveStateItemTitle: Equatable {
    case name
    case game
}

struct SaveStateItem: View {
    private static let formatter: RelativeDateTimeFormatter = .init()
    
    @EnvironmentObject private var persistence: Persistence
    
    @ObservedObject private var saveState: SaveStateObject
    private let titleValue: SaveStateItemTitle
    private let action: (SaveStateObject) -> Void
    
    @State private var isDeleteOpen: Bool = false
    @State private var isRenameOpen: Bool = false
    
    init(_ saveState: SaveStateObject, title: SaveStateItemTitle, action: @escaping (SaveStateObject) -> Void) {
        self.saveState = saveState
        self.titleValue = title
        self.action = action
    }
    
    var title: Text {
        switch titleValue {
        case .name:
            Text(
                verbatim: saveState.name,
                fallback: (saveState.isAuto ? "SAVE_STATE_AUTOMATIC" : "SAVE_STATE_UNNAMED")
            )
        case .game:
            Text(saveState.game?.name ?? "GAME")
        }
    }
    
    var body: some View {
        Button(action: selected) {
            DualLabeledImage(
                title: title,
                subtitle: Text(saveState.date ?? Date(), formatter: Self.formatter)
            ) {
                LocalImage(saveState.preview) { image in
                    image
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8.0)
                        .foregroundStyle(.secondary)
                }
                .aspectRatio(
                    CGFloat(saveState.game?.system.screenAspectRatio ?? 3 / 2),
                    contentMode: .fit
                )
                .overlay(alignment: .bottomLeading) {
                    Text("AUTO")
                        .font(.caption)
                        .textCase(.uppercase)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8.0)
                        .padding(.vertical, 6.0)
                        .foregroundStyle(.white)
                        .background(Material.thick)
                        .clipShape(RoundedRectangle(cornerRadius: 4.0))
                        .padding(8.0)
                        .colorScheme(.dark)
                        .opacity(saveState.isAuto && titleValue == .name ? 1 : 0)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !self.saveState.isAuto {
                ToggleButton(value: $isRenameOpen) {
                    Label("RENAME", systemImage: "character.cursor.ibeam")
                }
            }
            ToggleButton(role: .destructive, value: $isDeleteOpen) {
                Label("DELETE", systemImage: "trash")
            }
        }
        .renameItem("RENAME_SAVE_STATE", isPresented: $isRenameOpen, perform: rename)
        .deleteItem("DELETE_SAVE_STATE", isPresented: $isDeleteOpen, perform: delete) {
            Text("DELETE_SAVE_STATE_MESSAGE")
        }
    }
    
    private func selected() {
        self.action(self.saveState)
    }
    
    private func rename(_ newName: String) {
        Task {
            do {
                try await persistence.objects.rename(.init(saveState), to: newName)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
    
    private func delete() async {
        do {
            try await persistence.objects.delete(.init(saveState))
        } catch {
            // FIXME: Surface error
            print(error)
        }
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .previewStorage) {
    @Previewable @State var renameTarget: SaveStateObject?
    @Previewable @State var deleteTarget: SaveStateObject?

    PreviewSingleObjectView(SaveStateObject.fetchRequest()) { item, _ in
        SaveStateItem(item, title: .name) { _ in }
    }
}
