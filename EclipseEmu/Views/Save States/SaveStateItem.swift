import SwiftUI

enum SaveStateItemTitle: Equatable {
    case name
    case game
}

struct SaveStateItem: View {
    @EnvironmentObject private var persistence: Persistence

    @ObservedObject private var saveState: SaveStateObject
    @Binding private var renameTarget: SaveStateObject?
    @Binding private var deleteTarget: SaveStateObject?
    private let formatter: RelativeDateTimeFormatter
    private let titleValue: SaveStateItemTitle
    private let action: (SaveStateObject) -> Void

    init(
        _ saveState: SaveStateObject,
        title: SaveStateItemTitle,
        formatter: RelativeDateTimeFormatter,
        renameTarget: Binding<SaveStateObject?>,
        deleteTarget: Binding<SaveStateObject?>,
        action: @escaping (SaveStateObject) -> Void
    ) {
        self.saveState = saveState
        self.formatter = formatter
        self.titleValue = title
        self._renameTarget = renameTarget
        self._deleteTarget = deleteTarget
        self.action = action
    }

    var title: Text {
        switch titleValue {
        case .name:
            Text(saveState.name ?? (saveState.isAuto ? "Automatic State" : "Unnamed State"))
        case .game:
            Text(saveState.game?.name ?? "Game")
        }
    }

    var body: some View {
        Button(action: selected) {
            DualLabeledImage(title: title, subtitle: Text(saveState.date ?? Date(), formatter: formatter)) {
                LocalImage(saveState.preview) { image in
                    image
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8.0)
                        .foregroundStyle(.secondary)
                }
                .aspectRatio(3 / 2, contentMode: .fit)
                .overlay(alignment: .bottomLeading) {
                    Text("AUTO")
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
            if let game = saveState.game, titleValue == .game {
                NavigationLink(to: .game(game)) {
                    Label("Go to Game", systemImage: "arrow.right.square")
                }
            }
            if !self.saveState.isAuto {
                Button {
                    self.renameTarget = self.saveState
                } label: {
                    Label("Rename", systemImage: "character.cursor.ibeam")
                }
            }
            Button(role: .destructive, action: self.delete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func delete() {
        Task {
            do {
                try await persistence.objects.delete(.init(saveState))
            } catch {
                print(error)
            }
        }
    }

    private func selected() {
        self.action(self.saveState)
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    @Previewable @State var renameTarget: SaveStateObject?
    @Previewable @State var deleteTarget: SaveStateObject?

    PreviewSingleObjectView(SaveStateObject.fetchRequest()) { item, _ in
        SaveStateItem(
            item,
            title: .name,
            formatter: RelativeDateTimeFormatter(),
            renameTarget: $renameTarget,
            deleteTarget: $deleteTarget
        ) { _ in }
    }
}
