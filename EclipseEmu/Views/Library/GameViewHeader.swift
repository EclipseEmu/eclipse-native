import EclipseKit
import SwiftUI

struct GameViewHeader: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var persistence: Persistence
    @ObservedObject var game: Game
    var safeAreaTop: CGFloat
    var onPlayError: (PlayGameError, Game) -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 16.0) {
                BoxartView(game: self.game, cornerRadius: 8.0)
                    .frame(minWidth: 0.0, maxWidth: 300, minHeight: 0.0, maxHeight: 300)
                    .aspectRatio(1.0, contentMode: .fill)
                    .padding(.top)

                VStack {
                    Text(verbatim: self.game.name, fallback: "Unknown Game")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text(self.game.system.string)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                }
                .multilineTextAlignment(.center)
                .padding(.vertical)

                HStack(spacing: 8.0) {
                    PlayGameButton(game: game, onError: onPlayError)
                        .buttonStyle(.borderedProminent)

                    NavigationLink {
                        CheatsView(game: game)
                    } label: {
                        Label("Cheats", systemImage: "memorychip.fill")
                    }
                    .modify {
                        if #available(iOS 17.0, macOS 14.0, *) {
                            $0.tint(Color.accentColor.quaternary)
                        } else {
                            $0.tint(Color.accentColor.opacity(0.15))
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 4.0)
                .labelStyle(FullWidthLabelStyle())
                .font(.subheadline.weight(.semibold))
                .controlSize(.large)
            }
            .padding()
            .padding(.top, self.safeAreaTop)
        }
        .background(Material.thin)
        .background(ignoresSafeAreaEdges: .all)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
