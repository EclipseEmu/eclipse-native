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
    let onPlayError: (PlayGameAction.Failure, Game) -> Void

    @State var color: Color?
    @Environment(\.playGame) private var playGame
    @EnvironmentObject private var persistence: Persistence

    var body: some View {
        Button {
            viewModel.target = game
        } label: {
            VStack(alignment: .leading, spacing: 0.0) {
                AverageColorAsyncImage(url: persistence.files.url(path: game.boxart?.path) , averageColor: $color) { imagePhase in
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

                    PlayGameButton(game: game, onError: onPlayError)
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

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        GameKeepPlayingItem(game: game, viewModel: GameListViewModel(filter: .none)) { error, game in
            print(error, game)
        }
    }
}
