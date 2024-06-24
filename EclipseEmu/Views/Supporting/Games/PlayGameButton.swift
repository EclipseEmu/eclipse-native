import SwiftUI

struct PlayGameButton: View {
    @Environment(\.persistence) var persistence
    @Environment(\.playGame) var playGame
    
    @ObservedObject var game: Game
    let onError: (PlayGameAction.Failure, Persistence.Object<Game>) -> Void

    var body: some View {
        Button(action: play) {
            Label("Play", systemImage: "play.fill")
        }
    }

    func play() {
        Task {
            do {
                try await playGame(game: game, saveState: nil, persistence: persistence)
            } catch let error as PlayGameAction.Failure {
                onError(error, .init(object: game))
            } catch {
                onError(.unknown(error), .init(object: game))
            }
        }
    }
}

#Preview {
    let persistence = Persistence.preview
    let moc = persistence.viewContext
    let game = Game(context: moc)
    game.system = .gba
    game.md5 = "123"

    return PlayGameButton(game: game) { error, game in
        print(error, game)
    }
    .environment(\.persistence, persistence)
    .environment(\.managedObjectContext, moc)
}
