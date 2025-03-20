import SwiftUI

struct GamePicker: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: Persistence
    @ObservedObject var collection: Tag
    @State var searchQuery: String = ""
    @FetchRequest<Game>(sortDescriptors: [NSSortDescriptor(keyPath: \Game.name, ascending: true)])
    var games: FetchedResults<Game>

    var body: some View {
        NavigationStack {
            List(games) { game in
                let hasGame = isGameInCollection(game: game)
                HStack(spacing: 12.0) {
                    BoxartView(game: game, cornerRadius: 4.0)
                        .frame(minWidth: 44, maxWidth: 44)
                        .aspectRatio(1.0, contentMode: .fit)
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
        return game.tags?.contains(collection) ?? false
    }

    func toggleGame(game: Game) {
        Task {
            do {
                try await persistence.library.toggleTag(tag: .init(collection), for: .init(game))
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        PreviewSingleObjectView(Tag.fetchRequest()) { tag, _ in
            NavigationStack {
                GamePicker(collection: tag)
            }
        }
    }
}
