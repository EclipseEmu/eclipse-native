import SwiftUI

struct GameListGridItem: View {
    @ObservedObject var viewModel: GameListViewModel
    @ObservedObject var game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            BoxartView(game: game, cornerRadius: 8.0)
                .clipShape(RoundedRectangle(cornerRadius: 8.0))
                .overlay(alignment: .bottomTrailing) {
                    GameListItemSelectionToggle(viewModel: viewModel, game: game)
                        .padding([.trailing, .bottom], 8.0)
                }

            VStack(alignment: .leading) {
                Text(game.name ?? "Unknown Game")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(game.system.string)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let viewModel = GameListViewModel(filter: .none)
    let game = Game(context: PersistenceCoordinator.preview.context)
    game.name = "Test Game"
    game.system = .gba

    return GameListGridItem(viewModel: viewModel, game: game)
        .padding()
}
