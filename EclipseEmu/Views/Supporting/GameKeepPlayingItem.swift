import SwiftUI

struct GameKeepPlayingItem: View {
    static let playedDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var game: Game
    @Binding var selectedGame: Game?
    @Environment(\.playGame) private var playGame
    @Environment(\.persistenceCoordinator) private var persistence
    
    var body: some View {
        Button {
            selectedGame = game
        } label: {
            VStack(alignment: .leading, spacing: 0.0) {
                BoxartView()
                
                VStack(alignment: .leading) {
                    Text("Resume · \(game.datePlayed ?? Date(), formatter: Self.playedDateFormatter)")
                        .font(.caption.weight(.medium))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    
                    Text(game.name ?? "Unknown Game")
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    
                    Text(game.system.string)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: self.play) {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .modify {
                        if #available(macOS 14.0, *) {
                            $0.buttonBorderShape(.capsule)
                        } else {
                            $0
                        }
                    }
                    .tint(.white)
                    .foregroundStyle(.black)
                    .font(.subheadline.weight(.semibold))
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .multilineTextAlignment(.leading)
                .padding()
                .foregroundStyle(.white)
                .background(Material.ultraThin)
            }
        }.buttonStyle(PlainButtonStyle())
            .frame(minWidth: 140.0, idealWidth: 260.0, maxWidth: 260.0)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16.0))
            .clipped()
    }
    
    func play() {
        Task.detached {
            try await playGame(game: game, persistence: persistence)
        }
    }
}

#if DEBUG
#Preview {
    let viewContext = PersistenceCoordinator.preview.container.viewContext
    
    return GameKeepPlayingItem(
        game: Game(context: viewContext),
        selectedGame: .constant(nil)
    )
    .environment(\.managedObjectContext, viewContext)
}
#endif
