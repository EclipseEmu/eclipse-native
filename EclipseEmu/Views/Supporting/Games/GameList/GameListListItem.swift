import SwiftUI

struct GameListListItem: View {
    @ObservedObject var viewModel: GameListViewModel
    @ObservedObject var game: Game

    var body: some View {
        HStack(spacing: 16) {
            BoxartView(game: game, cornerRadius: 8.0)
                .frame(width: 64, height: 64)
                .aspectRatio(1.0, contentMode: .fit)
            VStack(alignment: .leading) {
                Text(game.name ?? "Game")
                    .lineLimit(2)
                Text(game.system.string)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            GameListItemSelectionToggle(viewModel: viewModel, game: game)
        }
        .contentShape(Rectangle())
        .padding()
        .background(.background)
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        GameListListItem(viewModel: .init(filter: .none), game: game)
    }
}
