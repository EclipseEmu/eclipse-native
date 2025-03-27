import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
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
        case .tag:
            ContentUnavailableMessage {
                Label("No Games", systemImage: "books.vertical.fill")
            } description: {
                Text("You haven't added any games to this collection.")
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview("Library", traits: .modifier(PreviewStorage())) {
    EmptyGameListMessage(filter: .none)
}

@available(iOS 18.0, macOS 15.0, *)
#Preview("Tag", traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Tag.fetchRequest()) { tag, _ in
        NavigationStack {
            EmptyGameListMessage(filter: .tag(tag))
        }
    }
}
