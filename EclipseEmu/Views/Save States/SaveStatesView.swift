import SwiftUI

struct SaveStatesView: View {
    private let dateFormatter = RelativeDateTimeFormatter()

    @EnvironmentObject private var persistence: Persistence

    @FetchRequest<SaveStateObject>(fetchRequest: SaveStateObject.fetchRequest())
    private var saveStates: FetchedResults<SaveStateObject>
    @ObservedObject private var game: GameObject
    private let action: (SaveStateObject) -> Void

    @State private var renameTarget: SaveStateObject?
    @State private var deleteTarget: SaveStateObject?

    init(game: GameObject, action: @escaping (SaveStateObject) -> Void) {
        let request = SaveStateObject.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SaveStateObject.isAuto, ascending: false),
            NSSortDescriptor(keyPath: \SaveStateObject.date, ascending: false)
        ]
        self._saveStates = .init(fetchRequest: request)

        self.game = game
        self.action = action
    }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)],
                spacing: 16.0
            ) {
                ForEach(saveStates) { saveState in
                    SaveStateItem(
                        saveState,
                        title: .name,
                        formatter: dateFormatter,
                        renameTarget: $renameTarget,
                        deleteTarget: $deleteTarget,
                        action: action
                    )
                }
            }
            .padding()
        }
        .emptyState(saveStates.isEmpty) {
            ContentUnavailableMessage {
                Label("NO_SAVE_STATES_TITLE", systemImage: "rectangle.grid.2x2")
            } description: {
                Text("NO_SAVE_STATES_MESSAGE")
            }
        }
        .renameItem("RENAME_SAVE_STATE", item: $renameTarget)
        .deleteItem("DELETE_SAVE_STATE", item: $deleteTarget) { saveState in
            Text("DELETE_SAVE_STATE_MESSAGE \(saveState.name ?? String(localized: "SAVE_STATE_UNNAMED"))")
        }
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        SaveStatesView(game: game) { _ in }
    }
}
