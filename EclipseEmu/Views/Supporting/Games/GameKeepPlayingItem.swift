import SwiftUI

#if os(macOS)
struct GameKeepPlayingPlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .buttonStyle(.plain)
            .padding(.horizontal, 12.0)
            .padding(.vertical, 6.0)
            .background(.white)
            .foregroundStyle(.black)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
#endif

struct GameKeepPlayingItem: View {
    @ObservedObject var game: Game
    @ObservedObject var viewModel: GameListViewModel
    @State var color: Color?
    @Environment(\.playGame) private var playGame
    @Environment(\.persistenceCoordinator) private var persistence

    var body: some View {
        Button {
            viewModel.target = game
        } label: {
            VStack(alignment: .leading, spacing: 0.0) {
                AverageColorAsyncImage(url: game.boxart?.path(in: persistence), averageColor: $color) { imagePhase in
                    switch imagePhase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                    case .empty:
                        Rectangle()
                            .foregroundStyle(.tertiary)
                    @unknown default:
                        ProgressView()
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    Rectangle()
                        .stroke(lineWidth: 1.0)
                        .foregroundStyle(.secondary)
                        .opacity(0.25)
                }

                VStack(alignment: .leading) {
                    Text(game.name ?? "Unknown Game")
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Text(game.system.string)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    PlayGameButton(game: game)
                    #if os(macOS)
                        .buttonStyle(GameKeepPlayingPlayButtonStyle())
                    #else
                        .buttonStyle(.borderedProminent)
                        .font(.subheadline.weight(.semibold))
                        .tint(.white)
                        .foregroundStyle(.black)
                        .buttonBorderShape(.capsule)
                    #endif
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .multilineTextAlignment(.leading)
                .padding()
                .foregroundStyle(.white)
                .background((self.color ?? .gray).brightness(-0.3))
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 140.0, idealWidth: 260.0, maxWidth: 260.0)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 16.0))
        .clipped()
        .contextMenu {
            GameListItemContextMenu(viewModel: viewModel, game: game)
        }
    }
}

#if DEBUG
#Preview {
    let viewModel = GameListViewModel(filter: .none)
    let viewContext = PersistenceCoordinator.preview.container.viewContext
    let game = Game(context: viewContext)
    game.id = UUID()
    game.md5 = "123"
    game.name = "Test Game"
    game.system = .gba

    return GameKeepPlayingItem(
        game: game,
        viewModel: viewModel
    )
    .environment(\.managedObjectContext, viewContext)
}
#endif
