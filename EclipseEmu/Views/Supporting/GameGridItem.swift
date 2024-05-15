import SwiftUI

struct GameGridItem: View {
    var game: Game
    @Binding var selectedGame: Game?
    @Environment(\.persistenceCoordinator) private var persistence

    var body: some View {
        Button {
            selectedGame = game
        } label: {
            VStack(alignment: .leading, spacing: 8.0) {
                BoxartView()
                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
                VStack(alignment: .leading) {
                    Text(game.name ?? "Unknown Game")
                        .lineLimit(2)
                    Text(game.system.string)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu(menuItems: {
            Button(role: .destructive, action: self.deleteGame) {
                Label("Delete Game", systemImage: "trash")
            }
        })
    }
    
    private func deleteGame() {
        Task {
            do {
                try await GameManager.delete(game: game, in: persistence)
                persistence.save()
            } catch {
                print(error)
            }
        }
    }
}

#if DEBUG
#Preview {
    let viewContext = PersistenceCoordinator.preview.container.viewContext
    
    return GameGridItem(game: Game(context: viewContext), selectedGame: .constant(nil))
        .padding()
        .environment(\.managedObjectContext, viewContext)
}
#endif
