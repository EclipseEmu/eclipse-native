import SwiftUI

struct SaveStatesView: View {
    private let dateFormatter = RelativeDateTimeFormatter()

    @EnvironmentObject private var persistence: Persistence

    @FetchRequest<SaveState>(fetchRequest: SaveState.fetchRequest())
    private var saveStates: FetchedResults<SaveState>
    @ObservedObject private var game: Game
    private let action: (SaveState) -> Void

    @State private var renameTarget: SaveState?
    @State private var deleteTarget: SaveState?

    init(game: Game, action: @escaping (SaveState) -> Void) {
        let request = SaveState.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SaveState.isAuto, ascending: false),
            NSSortDescriptor(keyPath: \SaveState.date, ascending: false)
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
                Label("No Save States", systemImage: "rectangle.grid.2x2")
            } description: {
                Text("You haven't made any save states for this game yet.")
            }
        }
        .renameItem("Rename State", item: $renameTarget)
        .deleteItem("Delete State", item: $deleteTarget) { saveState in
            Text("Are you sure you want to delete \(saveState.name ?? "this save state")?")
        }
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        SaveStatesView(game: game) { _ in }
    }
}
