import SwiftUI
import EclipseKit

final class PlayGameAction: ObservableObject {
    @Published var context: EmulationContext?
    
    struct EmulationContext {
        var core: GameCore
        var game: Game
    }
    
    enum Failure: Error {
        case missingCore
    }
    
    @MainActor
    public func callAsFunction(game: Game) async throws {
        try await MainActor.run {
            guard let core = EclipseEmuApp.cores.get(for: game) else {
                throw Failure.missingCore
            }
            self.context = EmulationContext(core: core, game: game)
        }
    }
    
    public func closeGame() async {
        await MainActor.run {
            self.context = nil
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
