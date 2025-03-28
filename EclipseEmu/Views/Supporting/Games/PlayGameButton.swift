import SwiftUI

struct PlayGameButton: View {
    @EnvironmentObject var persistence: Persistence
    @Environment(\.playGame) var playGame: PlayGameAction

    @ObservedObject var game: Game
    let onError: (PlayGameError, Game) -> Void

    var body: some View {
        Button(action: play) {
            Label("Play", systemImage: "play.fill")
        }
    }

    func play() {
        Task {
            do {
                try await playGame(
                    game: game,
                    saveState: nil,
                    persistence: persistence
                )
            } catch {
                onError(error as! PlayGameError, game)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        NavigationStack {
            PlayGameButton(game: game) { error, game in
                print(error, game)
            }
        }
    }
}
