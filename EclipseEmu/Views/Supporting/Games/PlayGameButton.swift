import SwiftUI

struct PlayGameButton: View {
    @Environment(\.persistenceCoordinator) var persistence
    @Environment(\.playGame) var playGame
    
    @ObservedObject var game: Game
    let onError: (PlayGameAction.Failure, Game) -> Void

    var body: some View {
        Button(action: play) {
            Label("Play", systemImage: "play.fill")
        }
    }

    func play() {
        Task.detached(priority: .userInitiated) {
            do {
                try await playGame(game: game, saveState: nil, persistence: persistence)
            } catch let error as PlayGameAction.Failure {
                await onError(error, game)
            } catch {
                await onError(.unknown(error), game)
            }
        }
    }
}

#Preview {
    let persistence = PersistenceCoordinator.preview
    let moc = persistence.context
    let game = Game(context: moc)
    game.system = .gba
    game.md5 = "123"

    return PlayGameButton(game: game) { error, game in
        print(error, game)
    }
    .environment(\.persistenceCoordinator, persistence)
    .environment(\.managedObjectContext, moc)
}
