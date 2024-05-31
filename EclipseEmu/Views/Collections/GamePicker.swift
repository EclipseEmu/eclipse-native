import SwiftUI

struct GamePicker: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.persistenceCoordinator) var persistence
    @ObservedObject var collection: GameCollection
    @State var searchQuery: String = ""
    @FetchRequest<Game>(sortDescriptors: [NSSortDescriptor(keyPath: \Game.name, ascending: true)])
    var games: FetchedResults<Game>

    var body: some View {
        CompatNavigationStack {
            List(games) { game in
                let hasGame = isGameInCollection(game: game)
                HStack(spacing: 12.0) {
                    BoxartView(game: game, cornerRadius: 4.0)
                        .frame(minWidth: 44, maxWidth: 44)
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

                    Button(role: hasGame ? .destructive : .none) {
                        self.toggleGame(game: game)
                    } label: {
                        Label(
                            hasGame ? "Remove Game" : "Add Game",
                            systemImage: hasGame ? "minus" : "plus"
                        )
                        .frame(width: 12, height: 12)
                        .imageScale(.small)
                        .aspectRatio(1.0, contentMode: .fit)
                    }
                    .modify {
                        if #available(iOS 17.0, macOS 14.0, *) {
                            $0.buttonBorderShape(.circle)
                                .fontWeight(.semibold)
                        } else {
                            $0
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .labelStyle(.iconOnly)
                }
            }
            .emptyState(games.isEmpty) {
                ContentUnavailableMessage {
                    Label("No Games", systemImage: "square.grid.2x2.fill")
                } description: {
                    Text("You don't have any games in your Library.")
                }
            }
            .searchable(text: $searchQuery)
            .onChange(of: searchQuery) { newValue in
                games.nsPredicate = newValue.isEmpty
                    ? nil
                    : NSPredicate(format: "name CONTAINS %@", newValue)
            }
            .navigationTitle("Select Games")
#if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
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
        return game.collections?.contains(collection) ?? false
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
