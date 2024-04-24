import SwiftUI

struct GameViewHeader: View {
    var game: Game
    var safeAreaTop: CGFloat
    @Environment(\.playGame) var playGame
    @Environment(\.colorScheme) var colorScheme
    
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
            try await playGame(game: game)
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
                    
                    SectionHeader(title: "Save States").padding([.horizontal, .top])
                    ScrollView(.horizontal) {
                        LazyHStack {
                            VStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8.0)
                                    .aspectRatio(1.5, contentMode: .fit)
                                Text("Auto · 5h ago").foregroundStyle(.secondary)
                            }.frame(minWidth: 140.0, idealWidth: 200.0, maxWidth: 260.0)
                            Divider()
                            ForEach(0..<10) { _ in
                                VStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8.0)
                                        .aspectRatio(1.5, contentMode: .fit)
                                    Text("Manual · 8h ago").foregroundStyle(.secondary)
                                }.frame(minWidth: 140.0, idealWidth: 200.0, maxWidth: 260.0)
                            }
                        }.padding(.horizontal)
                    }.padding(.bottom)
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

#Preview { let context = PersistenceController.preview.container.viewContext
    
    return VStack {}
        .sheet(item: .constant(Game(context: context))) {
            GameView(game: $0)
        }
        .environment(\.managedObjectContext, context)
}
