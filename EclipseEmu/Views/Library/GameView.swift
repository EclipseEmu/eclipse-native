import SwiftUI

struct GameViewHeader: View {
    var game: Game
    var safeAreaTop: CGFloat
    @Environment(\.playGame) var playGame
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.persistenceCoordinator) var persistence

    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 12.0)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(minWidth: 0.0, maxWidth: 275)
                
                VStack {
                    Text(game.name ?? "Unknown Game")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text(game.system.string)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                }
                .multilineTextAlignment(.center)
                .padding(.vertical, 8.0)
                
                Button(action: self.play) {
                    Label("Play", systemImage: "play.fill")
                        .frame(maxWidth: 200)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .font(.subheadline.weight(.semibold))
                .controlSize(.large)
                .tint(.black)
                .foregroundStyle(.white)
            }
            .padding()
            .padding(.bottom)
            .padding(.top, safeAreaTop)
        }
        .background(Material.regular)
        .background(ignoresSafeAreaEdges: .all)
        .overlay(
            Rectangle()
                .frame(width: nil, height: 1, alignment: .bottom)
            #if os(macOS)
                .foregroundStyle(Color(nsColor: .separatorColor))
            #else
                .opacity(0.25)
                .modify {
                    if #available(iOS 17.0, *) {
                        $0.foregroundStyle(.separator)
                    } else {
                        $0
                    }
                }
            #endif
            , alignment: .bottom
        )
    }
    
    func play() {
        Task.detached {
            try await playGame(game: game, persistence: persistence)
        }
    }
}

struct GameView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    var game: Game
    
    var body: some View {
        CompatNavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    GameViewHeader(game: game, safeAreaTop: geometry.safeAreaInsets.top)
//                    SectionHeader(title: "Save States").padding([.horizontal, .top])
                    
                    LazyVStack(alignment: .leading) {
                        NavigationLink(destination: CheatsView(game: game)) {
                            Label("Cheats", systemImage: "doc.badge.gearshape")
                                .padding()
                        }
                        .modify {
                            if #available(iOS 17.0, macOS 14.0, *) {
                                $0.background(.background.secondary)
                            } else {
#if canImport(UIKit)
                                $0.background(Color(uiColor: .secondarySystemGroupedBackground))
#elseif canImport(AppKit)
                                $0.background(Color(nsColor: .underPageBackgroundColor))
#endif
                            }
                        }
                        .padding(.all)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: DismissButton.placement) {
                    DismissButton()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    let context = PersistenceCoordinator.preview.container.viewContext
    let game = Game(context: context)
    game.system = .gba
    
    return GameView(game: game).environment(\.managedObjectContext, context)
}
#endif
