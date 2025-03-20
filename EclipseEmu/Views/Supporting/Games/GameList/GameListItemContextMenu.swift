import SwiftUI

struct GameListItemContextMenu: View {
    @ObservedObject var viewModel: GameListViewModel
    @ObservedObject var game: Game

    var body: some View {
        Group {
            Button {
                viewModel.renameTarget = game
            } label: {
                Label("Rename", systemImage: "character.cursor.ibeam")
            }

            Button {
                viewModel.selection.removeAll()
                viewModel.selection.insert(game)
                viewModel.isAddToCollectionOpen = true
            } label: {
                Label("Add to Collection", systemImage: "text.badge.plus")
            }

            Menu {
                Button {} label: {
                    Label("From Photos", systemImage: "photo.on.rectangle")
                }.disabled(true)
                Button {
                    viewModel.changeBoxartTarget = game
                } label: {
                    Label("From Database", systemImage: "magnifyingglass")
                }
            } label: {
                Label("Replace Box Art", systemImage: "photo")
            }
            Divider()
            Button(role: .destructive) {
                viewModel.selection.removeAll()
                viewModel.selection.insert(game)
                viewModel.isDeleteConfirmationOpen = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        Text("Context Menu")
            .contextMenu {
                GameListItemContextMenu(
                    viewModel: .init(filter: .none),
                    game: game
                )
            }
    }
}
