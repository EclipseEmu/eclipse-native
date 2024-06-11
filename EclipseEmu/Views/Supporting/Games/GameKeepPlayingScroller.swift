import SwiftUI

struct GameKeepPlayingScroller<Games: RandomAccessCollection>: View where Games.Element == Game {
    var games: Games
    @ObservedObject var viewModel: GameListViewModel
    let onPlayError: (PlayGameAction.Failure, Game) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 16.0) {
                ForEach(games) { game in
                    GameKeepPlayingItem(game: game, viewModel: viewModel, onPlayError: onPlayError)
                }
            }
            .padding([.horizontal, .bottom])
        }
//        .playGameErrorAlert(errorModel: errorModel)
    }
}

#Preview {
    GameKeepPlayingScroller(games: [], viewModel: GameListViewModel(filter: .none)) { error, game in

    }
}
