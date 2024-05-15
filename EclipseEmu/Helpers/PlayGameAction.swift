import SwiftUI
import EclipseKit
import CoreData

final class PlayGameAction: ObservableObject {
    @Published var model: EmulationViewModel?
    
    enum Failure: Error {
        case missingCore
    }
    
    public func callAsFunction(game: Game, persistence: PersistenceCoordinator) async throws {
        guard let core = await EclipseEmuApp.cores.get(for: game) else {
            throw Failure.missingCore
        }
        
        let data = try GameManager.emulationData(for: game, in: persistence)
        let model = EmulationViewModel(coreInfo: core, game: game, persistence: persistence, emulationData: data)
        
        GameManager.updateDatePlayed(for: game, in: persistence)
        
        await MainActor.run {
            self.model = model
        }
    }
    
    public func closeGame() async {
        await MainActor.run {
            self.model = nil
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
