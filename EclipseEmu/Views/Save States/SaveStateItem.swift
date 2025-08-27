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
    private let aspectRatio: CGFloat
    
    @State private var isDeleteOpen: Bool = false
    @State private var isRenameOpen: Bool = false
    
    init(_ saveState: SaveStateObject, title: SaveStateItemTitle, action: @escaping (SaveStateObject) -> Void) {
        self.saveState = saveState
        self.titleValue = title
        self.action = action
        self.aspectRatio = CGFloat(saveState.game?.system.screenAspectRatio ?? 3 / 2)
    }
    
    private var title: Text {
        switch titleValue {
        case .name where saveState.isAuto:
            Text(verbatim: saveState.name, fallback: "SAVE_STATE_AUTOMATIC")
        case .name:
            Text(verbatim: saveState.name, fallback: "SAVE_STATE_UNNAMED")
        case .game:
            Text(saveState.game?.name ?? "GAME")
        }
    }
    
    private var subtitle: Text {
        Text(saveState.date ?? Date(), formatter: Self.formatter)
    }
    
    var body: some View {
        Button(action: selected) {
            DualLabeledImage(title: title, subtitle: subtitle, image: saveState.preview, aspectRatio: aspectRatio, cornerRadius: 12.0, overlay: autoBadge)
        }
        .buttonStyle(.plain)
        .contextMenu(menuItems: menuItems, preview: preview)
        .renameItem("RENAME_SAVE_STATE", item: saveState, isPresented: $isRenameOpen)
        .deleteItem("DELETE_SAVE_STATE", isPresented: $isDeleteOpen, perform: delete) {
            Text("DELETE_SAVE_STATE_MESSAGE")
        }
    }
    
    @ViewBuilder
    func menuItems() -> some View {
        if !self.saveState.isAuto {
            ToggleButton("RENAME", systemImage: "character.cursor.ibeam", value: $isRenameOpen)
        }
        ToggleButton("DELETE", systemImage: "trash", role: .destructive, value: $isDeleteOpen)
    }
    
    @ViewBuilder
    func preview() -> some View {
        DualLabeledImage(
            title: title,
            subtitle: subtitle,
            image: saveState.preview,
            aspectRatio: aspectRatio,
            cornerRadius: 12.0,
            idealWidth: 192.0,
            overlay: autoBadge
        )
        .padding()
        .environmentObject(persistence)
    }
    
    func autoBadge() -> some View {
        Text("AUTO")
            .font(.caption)
            .textCase(.uppercase)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8.0)
            .padding(.vertical, 6.0)
            .background(Material.thick)
            .foregroundStyle(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
            .colorScheme(.dark)
            .padding(8.0)
            .opacity(saveState.isAuto && titleValue == .name ? 1 : 0)
    }
    
    private func selected() {
        self.action(self.saveState)
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
    
    PreviewSingleObjectView<SaveStateObject, _>({
        let request = SaveStateObject.fetchRequest()
        request.predicate = NSPredicate(format: "isAuto == true")
        return request
    }()) { item, _ in
        SaveStateItem(item, title: .name) { _ in }
            .padding()
    }
}
