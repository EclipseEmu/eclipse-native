import SwiftUI

struct PlayGameButton: View {
    @Environment(\.persistenceCoordinator) var persistence
    @Environment(\.playGame) var playGame
    var game: Game

    var body: some View {
        Button(action: play) {
            Label("Play", systemImage: "play.fill")
        }
    }

    func play() {
        Task.detached(priority: .userInitiated) {
            do {
                try await playGame(game: game, saveState: nil, persistence: persistence)
            } catch let PlayGameAction.Failure.missingFile(missingKind) {
                print("missing file: \(missingKind)")
            } catch PlayGameAction.Failure.missingCore {
                print("missing core")
            } catch {
                print("An unknown error occured")
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

    return PlayGameButton(game: game)
        .environment(\.persistenceCoordinator, persistence)
        .environment(\.managedObjectContext, moc)
}
