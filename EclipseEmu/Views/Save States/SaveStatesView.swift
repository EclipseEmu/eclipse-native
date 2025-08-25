import SwiftUI

struct SaveStatesView: View {
    private let dateFormatter = RelativeDateTimeFormatter()

    @EnvironmentObject private var persistence: Persistence

    @FetchRequest<SaveStateObject>(fetchRequest: SaveStateObject.fetchRequest())
    private var saveStates: FetchedResults<SaveStateObject>
    @ObservedObject private var game: GameObject
    private let action: (SaveStateObject) -> Void

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
                    SaveStateItem(saveState, title: .name, action: action)
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
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .previewStorage) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        SaveStatesView(game: game) { _ in }
    }
}
