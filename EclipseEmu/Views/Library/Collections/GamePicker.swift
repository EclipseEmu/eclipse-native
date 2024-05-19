import SwiftUI

struct GamePicker: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.persistenceCoordinator) var persistence
    @FetchRequest<Game>(sortDescriptors: [NSSortDescriptor(keyPath: \Game.name, ascending: true)])
    var games: FetchedResults<Game>
    @ObservedObject var collection: GameCollection
    
    @State var searchQuery: String = ""

    var body: some View {
        let _ = Self._printChanges()
        CompatNavigationStack {
            List(games) { game in
                HStack(spacing: 12.0) {
                    BoxartView()
                        .frame(minWidth: 44, maxWidth: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                    VStack(alignment: .leading) {
                        Text(game.name ?? "Unknown Game")
                            .lineLimit(1)
                        Text(game.system.string)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: { self.toggleGame(game: game) }) {
                        if isGameInCollection(game: game) {
                            Label("Remove Game", systemImage: "minus.circle")
                                .labelStyle(.iconOnly)
                        } else {
                            Label("Add Game", systemImage: "plus.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                }.id(game.id)
            }
            .emptyState(games.isEmpty) {
                ScrollView {
                    EmptyMessage {
                        Text("No Games")
                    } message: {
                        Text("You don't have any games in your library. You can add some by pressing the \(Image(systemName: "plus")) in your library.")
                    }
                }
            }
            .searchable(text: $searchQuery)
            .onChange(of: searchQuery) { newValue in
                games.nsPredicate = newValue.isEmpty
                    ? nil
                    : NSPredicate(format: "name CONTAINS %@", newValue)
            }
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DismissButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }
    
    @inlinable
    func isGameInCollection(game: Game) -> Bool {
        guard !game.isDeleted else { return false }
        return game.collections?.contains(self.collection) ?? false
    }
    
    func toggleGame(game: Game) {
        if isGameInCollection(game: game) {
            collection.removeFromGames(game)
        } else {
            collection.addToGames(game)
        }
        persistence.saveIfNeeded()
    }
}

#Preview {
    let context = PersistenceCoordinator.preview.context
    let game = Game(context: context)
    game.id = UUID()
    game.system = .gba
    game.name = "My Game"
    let collection = GameCollection(context: context)
    collection.name = "Foobar"
    collection.icon = .symbol("list.bullet")
    collection.color = GameCollection.Color.blue.rawValue
    collection.addToGames(game)
    
    return GamePicker(collection: collection)
        .environment(\.managedObjectContext, context)
}
