import SwiftUI

struct EmptyGameListMessage: View {
    let filter: GameListViewModel.Filter

    var body: some View {
        switch filter {
        case .none:
            ContentUnavailableMessage {
                Label("No Games", systemImage: "books.vertical.fill")
            } description: {
                Text("You haven't added any games to your library.")
            }
        case .collection(_):
            ContentUnavailableMessage {
                Label("No Games", systemImage: "books.vertical.fill")
            } description: {
                Text("You haven't added any games to this collection.")
            }
        }
    }
}

#Preview("Library") {
    EmptyGameListMessage(filter: .none)
}

#Preview("Collection") {
    EmptyGameListMessage(filter: .collection(GameCollection(context: PersistenceCoordinator.preview.context)))
}
