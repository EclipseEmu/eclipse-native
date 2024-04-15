import SwiftUI

struct GameGridItem: View {
    var game: Game
    @Binding var selectedGame: Game?
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        Button {
            selectedGame = game
        } label: {
            VStack(alignment: .leading, spacing: 8.0) {
                RoundedRectangle(cornerRadius: 8.0)
                    .aspectRatio(1.0, contentMode: .fit)
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
        withAnimation {
            viewContext.delete(game)
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    GameGridItem(game: Game(), selectedGame: .constant(nil))
}
