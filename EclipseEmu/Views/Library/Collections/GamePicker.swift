import SwiftUI

struct GamePicker<ActionContent: View>: View {
    @Environment(\.dismiss) var dismiss
    @FetchRequest<Game>(sortDescriptors: [NSSortDescriptor(keyPath: \Game.name, ascending: true)])
    var games: FetchedResults<Game>
    
    let actionContent: (Game) -> ActionContent
    
    @State var searchQuery: String = ""

    var body: some View {
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
                    actionContent(game)
                }
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
}

#Preview {
    let context = PersistenceCoordinator.preview.context
    let game = Game(context: context)
    game.id = UUID()
    game.system = .gba
    game.name = "My Game"
    
    return GamePicker { game in
        Button {
            print(game)
        } label: {
            Label("Add Game", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
    }
    .environment(\.managedObjectContext, context)
}
