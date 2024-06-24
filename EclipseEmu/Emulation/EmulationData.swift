import Foundation

struct EmulationData: Sendable {
    public let romPath: URL
    public let savePath: URL
    public let cheats: [CheatData]

    struct CheatData: Hashable, Sendable {
        let original: Persistence.Object<Cheat>
        let code: String
        let type: String
    }

    init(game: Game) throws {
        guard let romPath = game.romPath?.path(in: .shared) else {
            throw PlayGameAction.Failure.romPathInvalid
        }
        
        guard let savePath = game.savePath.path(in: .shared) else {
            throw PlayGameAction.Failure.savePathInvalid
        }

        self.romPath = romPath
        self.savePath = savePath
        
        if let cheats = game.cheats as? Set<Cheat> {
            self.cheats = cheats.compactMap { cheat in
                guard cheat.enabled, let code = cheat.code, let type = cheat.type else { return nil }
                return CheatData(original: .init(object: cheat), code: code, type: type)
            }
        } else {
            self.cheats = []
        }
    }
}
