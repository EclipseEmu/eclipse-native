import SwiftUI

struct GameViewHeader: View {
    @ObservedObject var game: Game
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
                BoxartView(game: self.game, cornerRadius: 8.0)
                    .frame(minWidth: 0.0, idealWidth: 275, maxWidth: 275)

                VStack {
                    Text(self.game.name ?? "Unknown Game")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text(self.game.system.string)
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
            .padding(.top, self.safeAreaTop)
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

    @SectionedFetchRequest<Bool, SaveState>(sectionIdentifier: \.isAuto, sortDescriptors: [])
    var saveStates
    @State var renameSaveStateDialogTarget: SaveState?
    @State var renameGameDialogTarget: Game?
    @State var isChangeBoxartFromDatabaseOpen = false

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

                    SectionHeader("Save States")
                        .padding([.horizontal, .top])
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(self.saveStates) { section in
                                ForEach(section) { saveState in
                                    SaveStateItem(
                                        saveState: saveState,
                                        action: .startWithState(game),
                                        renameDialogTarget: $renameSaveStateDialogTarget
                                    )
                                    .frame(minWidth: 140.0, idealWidth: 200.0, maxWidth: 260.0)
                                }
                                if section.id {
                                    Divider()
                                }
                            }
                        }
                        .padding([.horizontal, .bottom])
                    }
                    .emptyState(self.saveStates.isEmpty) {
                        EmptyMessage {
                            Text("No Save States")
                        } message: {
                            Text("You haven't made any save states for this game. Use the \"Save State\" button in the emulation menu to create some.")
                        }
                    }

                    LazyVStack(alignment: .leading) {
                        NavigationLink {
                            CheatsView(game: game)
                        } label: {
                            Label("Cheats", systemImage: "doc.badge.gearshape")
                        }
                        Divider()
                        NavigationLink {
                            GameManageCollectionsView(game: game)
                        } label: {
                            Label("Manage Collections", systemImage: "square.on.square")
                        }
                    }
                    .padding()
                }
                .ignoresSafeArea(edges: .top)
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            self.renameGameDialogTarget = self.game
                        } label: {
                            Label("Rename", systemImage: "rectangle.and.pencil.and.ellipsis")
                        }

                        Menu {
                            Button {} label: {
                                Label("From Photos", systemImage: "photo.on.rectangle")
                            }.disabled(true)

                            Button {
                                self.isChangeBoxartFromDatabaseOpen = true
                            } label: {
                                Label("From Database", systemImage: "magnifyingglass")
                            }
                        } label: {
                            Label("Replace Boxart", systemImage: "photo")
                        }

                        Divider()

                        Button(role: .destructive, action: self.delete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Label("Game Options", systemImage: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                }
            }
            .renameAlert(
                $renameSaveStateDialogTarget,
                key: \.name,
                title: "Rename State",
                placeholder: "State Name"
            ) { saveState, name in
                SaveStateManager.rename(saveState, to: name, in: persistence)
            }
            .renameAlert(
                $renameGameDialogTarget,
                key: \.name,
                title: "Rename Game",
                placeholder: "Game Name"
            ) { game, name in
                GameManager.rename(game, to: name, in: persistence)
            }
            .sheet(isPresented: $isChangeBoxartFromDatabaseOpen) {
                BoxartPicker(system: game.system, initialQuery: game.name ?? "", finished: self.photoFromDatabase)
            }
        }
    }

    func photoFromDatabase(entry: OpenVGDB.Item) {
        guard let url = entry.boxart else { return }
        Task {
            do {
                game.boxart = try await ImageAssetManager.create(remote: url, in: persistence, save: false)
                persistence.saveIfNeeded()
            } catch {
                // FIXME: present this to the user
                print(error)
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

    func delete() {
        Task {
            await MainActor.run {
                dismiss()
            }
            try? await GameManager.delete(self.game, in: self.persistence)
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
