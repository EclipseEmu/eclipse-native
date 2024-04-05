import SwiftUI

struct GameGridItem: View {
    var game: Game
    @Binding var selectedGame: Game?
    
    var body: some View {
        Button {
            selectedGame = game
        } label: {
            VStack(alignment: .leading, spacing: 8.0) {
                RoundedRectangle(cornerRadius: 8.0)
                    .aspectRatio(1.0, contentMode: .fit)
                VStack(alignment: .leading) {
                    Text(game.name ?? "Unknown Game")
                    Text(game.system.string)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }.buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GameGridItem(game: Game(), selectedGame: .constant(nil))
}
