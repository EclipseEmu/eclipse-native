import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct GameListGridItem: View {
    @ObservedObject var viewModel: GameListViewModel
    @ObservedObject var game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            BoxartView(game: game, cornerRadius: 8.0)
                .aspectRatio(1.0, contentMode: .fill)
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

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        GameListGridItem(
            viewModel: .init(filter: .none),
            game: game
        ).padding()
    }
}
