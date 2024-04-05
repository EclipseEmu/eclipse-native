import Foundation
import SwiftUI

final class PlayGameAction: ObservableObject {
    @Published var game: Game?
    
    @MainActor
    public func callAsFunction(game: Game) async throws {
        await MainActor.run {
            self.game = game
        }
    }
    
    public func closeGame() async {
        await MainActor.run {
            self.game = nil
        }
    }
}

// MARK: setup @Environment

private struct PlayGameActionKey: EnvironmentKey {
    static let defaultValue: PlayGameAction = PlayGameAction()
}

extension EnvironmentValues {
    var playGame: PlayGameAction {
        get { self[PlayGameActionKey.self] }
        set { self[PlayGameActionKey.self] = newValue }
    }
}
