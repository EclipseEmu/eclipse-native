import SwiftUI
import EclipseKit
import CoreData

final class PlayGameAction: ObservableObject {
    @Published var model: EmulationViewModel?
    
    enum Failure: Error {
        case missingCore
    }
    
    public func callAsFunction(game: Game, viewContext: NSManagedObjectContext) async throws {
        guard let core = await EclipseEmuApp.cores.get(for: game) else {
            throw Failure.missingCore
        }
        let model = EmulationViewModel(coreInfo: core, game: game)
        await MainActor.run {
            self.model = model
        }
        
        do {
            game.datePlayed = Date()
            try viewContext.save()
        } catch {
            print(error)
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
