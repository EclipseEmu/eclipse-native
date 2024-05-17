import SwiftUI

struct GameKeepPlayingScroller<Games: RandomAccessCollection>: View where Games.Element == Game {
    var games: Games
    @Binding var selectedGame: Game?
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 16.0) {
                ForEach(games) { game in
                    GameKeepPlayingItem(game: game, selectedGame: $selectedGame)
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
}

#Preview {
    GameKeepPlayingScroller(games: [], selectedGame: .constant(nil))
}
