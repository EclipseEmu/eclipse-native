import SwiftUI

struct GameViewHeader: View {
    var game: Game
    var safeAreaTop: CGFloat
    var play: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.persistenceCoordinator) var persistence
    
    init(game: Game, safeAreaTop: CGFloat, play: @escaping () -> Void) {
        self.game = game
        self.safeAreaTop = safeAreaTop
        self.play = play
    }

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
}

struct GameView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    var game: Game
    
    @Environment(\.persistenceCoordinator) var persistence
    @Environment(\.playGame) var playGame

    @SectionedFetchRequest<Bool, SaveState>(sectionIdentifier: \.isAuto, sortDescriptors: SaveStatesListView.sortDescriptors) var saveStates
    @State var isRenameSaveStateDialogOpen = false
    @State var renameSaveStateDialogText: String = ""
    @State var renameSaveStateDialogTarget: SaveState?
    
    init(game: Game) {
        self.game = game
        let request = SaveStateManager.listRequest(for: game, limit: 10)
        request.sortDescriptors = SaveStatesListView.sortDescriptors
        self._saveStates = SectionedFetchRequest(fetchRequest: request, sectionIdentifier: \.isAuto)
    }

    var body: some View {
        CompatNavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    GameViewHeader(game: game, safeAreaTop: geometry.safeAreaInsets.top) {
                        self.play(saveState: nil)
                    }
                    SectionHeader(title: "Save States").padding([.horizontal, .top])
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(self.saveStates) { section in
                                ForEach(section) { saveState in
                                    SaveStateItem(saveState: saveState, action: self.selectedSaveState, renameDialogTarget: $renameSaveStateDialogTarget)
                                        .frame(minWidth: 140.0, idealWidth: 200.0, maxWidth: 260.0)
                                }
                                if section.id {
                                    Divider()
                                }
                            }
                        }.padding([.horizontal, .bottom])
                    }
                    .emptyState(self.saveStates.isEmpty) {
                        MessageBlock {
                            Text("No Save States")
                                .fontWeight(.medium)
                                .padding([.top, .horizontal], 8.0)
                            Text("You haven't made any save states for this game. Use the \"Save State\" button in the emulation menu to create some.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding([.bottom, .horizontal], 8.0)
                        }
                    }
                    
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
            .onChange(of: renameSaveStateDialogTarget, perform: { saveState in
                if let saveState {
                    self.renameSaveStateDialogText = saveState.name ?? ""
                    self.isRenameSaveStateDialogOpen = true
                } else {
                    self.renameSaveStateDialogText = ""
                }
            })
           .alert("Rename State", isPresented: $isRenameSaveStateDialogOpen) {
                Button("Cancel", role: .cancel) {
                    self.renameSaveStateDialogTarget = nil
                    self.renameSaveStateDialogText = ""
                }
                Button("Rename") {
                    print("rename")
                    guard let renameSaveStateDialogTarget else { return }
                    SaveStateManager.rename(renameSaveStateDialogTarget, to: renameSaveStateDialogText, in: persistence)
                    self.renameSaveStateDialogTarget = nil
                }
                TextField("Save State Name", text: $renameSaveStateDialogText)
            }
        }
    }
    
    func selectedSaveState(saveState: SaveState, dismissAction: DismissAction) {
        self.play(saveState: saveState)
    }
    
    func play(saveState: SaveState?) {
        Task.detached {
            do {
                try await playGame(game: game, saveState: saveState, persistence: persistence)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("failed to launch game: \(error.localizedDescription)")
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
