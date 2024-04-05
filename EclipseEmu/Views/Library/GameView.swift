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
                .padding(.vertical, 8.0)
                
                Button(action: self.play) {
                    Label("Play", systemImage: "play.fill")
                        .frame(maxWidth: 200)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .font(.subheadline)
                .fontWeight(.semibold)
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
#if os(macOS)
        .overlay(Rectangle().frame(width: nil, height: 1, alignment: .bottom).foregroundColor(colorScheme == .light ? .init(white: 0.5, opacity: 0.25) : .init(white: 0.0, opacity: 0.5)), alignment: .bottom)
#else
        .overlay(
            Rectangle()
                .frame(width: nil, height: 1, alignment: .bottom)
                .opacity(0.25)
                .modify {
                    if #available(iOS 17.0, *) {
                        $0.foregroundStyle(.separator)
                    } else {
                        $0
                    }
                },
            alignment: .bottom
        )
#endif
    }
    
    func play() {
        Task {
            try await playGame(game: game)
        }
    }
}

struct GameView: View {
    var game: Game
    
    @Environment(\.dismiss)
    var dismiss: DismissAction
    
    var body: some View {
        NavigationStack {
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
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismissAction: dismiss)
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    CloseButton(dismissAction: dismiss)
                }
                #endif
            }
        }
    }
}

#Preview {
    Text("").sheet(item: .constant(Game())) {
        GameView(game: $0)
    }.environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
