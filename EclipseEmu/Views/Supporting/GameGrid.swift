import SwiftUI

struct GameGrid<Games: RandomAccessCollection>: View where Games.Element == Game {
    var games: Games
    @Binding var selectedGame: Game?
    
    var body: some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)], spacing: 16.0) {
            ForEach(games) { item in
                GameGridItem(game: item, selectedGame: $selectedGame)
            }
        }
    }
}
