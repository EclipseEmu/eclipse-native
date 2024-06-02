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

#Preview {
    let viewModel = GameListViewModel(filter: .none)
    let game = Game(context: PersistenceCoordinator.preview.context)
    game.name = "Test Game"
    game.system = .gba

    return Text("Context Menu")
        .contextMenu {
            GameListItemContextMenu(viewModel: viewModel, game: game)
        }
}
