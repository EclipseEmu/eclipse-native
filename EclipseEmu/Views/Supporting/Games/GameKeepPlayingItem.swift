import SwiftUI

struct GameKeepPlayingItem: View {
    @ObservedObject var game: Game
    @ObservedObject var viewModel: GameListViewModel
    @State var color: Color? = nil
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
                    case .failure(_):
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
    
    func play() {
        Task.detached {
            do {
                try await playGame(game: game, saveState: nil, persistence: persistence)
            } catch {
                print("failed to launch game: \(error.localizedDescription)")
            }
        }
    }
}

#if DEBUG
#Preview {
    let viewModel = GameListViewModel(filter: .none)
    let viewContext = PersistenceCoordinator.preview.container.viewContext
    
    return GameKeepPlayingItem(
        game: Game(context: viewContext),
        viewModel: viewModel
    )
    .environment(\.managedObjectContext, viewContext)
}
#endif
