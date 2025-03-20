import EclipseKit
import SwiftUI

final class GameViewModel: ObservableObject {
    @Published var isErrored: PlayGameAction.Failure?
}

struct GameViewHeader: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var persistence: Persistence
    @ObservedObject var game: Game
    var safeAreaTop: CGFloat
    var onPlayError: (PlayGameAction.Failure, Game) -> Void

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

struct GameViewSaveStatesList: View {
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.playGame) private var playGame
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var game: Game
    @Binding var renameTarget: SaveState?
    let onPlayError: (PlayGameAction.Failure, Game) -> Void

    @SectionedFetchRequest<Bool, SaveState>(sectionIdentifier: \.isAuto, sortDescriptors: [])
    private var saveStates

    init(game: Game, renameTarget: Binding<SaveState?>, onPlayError: @escaping (PlayGameAction.Failure, Game) -> Void) {
        self.game = game
        self._renameTarget = renameTarget
        self.onPlayError = onPlayError

        let request = SaveState.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.includesSubentities = false
        request.fetchLimit = 10
        request.sortDescriptors = SaveStatesListView.sortDescriptors
        self._saveStates = SectionedFetchRequest(fetchRequest: request, sectionIdentifier: \.isAuto)
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(self.saveStates) { section in
                    ForEach(section) { saveState in
                        SaveStateItem(
                            saveState: saveState,
                            action: self.saveStateSelected,
                            renameDialogTarget: $renameTarget
                        )
                        .frame(minWidth: 140.0, idealWidth: 200.0, maxWidth: 260.0)
                    }
                    if section.id == saveStates.first?.id && saveStates.count > 1 {
                        Divider()
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
        .emptyState(saveStates.isEmpty) {
            EmptyMessage {
                Text("No Save States")
            } message: {
                Text("You haven't made any save states for this game. Use the \"Save State\" button in the emulation menu to create some.")
            }
        }
    }

    func saveStateSelected(_ state: SaveState) {
        Task {
            do {
                try await playGame(
                    game: game,
                    saveState: state,
                    persistence: persistence
                )
                dismiss()
            } catch let error as PlayGameAction.Failure {
                onPlayError(error, game)
            } catch {
                onPlayError(.unknown(error), game)
            }
        }
    }
}

struct GameView: View {
    @ObservedObject var game: Game

    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.playGame) private var playGame

    @StateObject private var playGameErrorModel = PlayGameErrorModel()
    @State private var isChangeBoxartFromDatabaseOpen = false
    @State private var isChangeBoxartFromPhotosOpen = false
    @State private var selectedPhoto: Result<CGImage, any Error>?

    @State private var isRenameGameOpen: Bool = false
    @State private var renameGameText: String = ""
    @State private var renameSaveStateTarget: SaveState?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    GameViewHeader(game: game, safeAreaTop: geometry.safeAreaInsets.top, onPlayError: onPlayError)

                    Section {
                        GameViewSaveStatesList(game: game, renameTarget: $renameSaveStateTarget, onPlayError: onPlayError)
                    } header: {
                        SectionHeader("Save States")
                            .padding([.horizontal, .top])
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 16.0) {
                            DataPointView(title: "Date Added") {
                                Text(game.dateAdded, format: .dateTime, fallback: "Unknown")
                            }
                            DataPointView(title: "Last Played") {
                                Text(game.datePlayed, format: .dateTime, fallback: "Never")
                            }
                            DataPointView(title: "MD5 Checksum") {
                                Text(verbatim: game.md5, fallback: "Unknown")
                                    .font(.caption.monospaced())
                            }
                        }
                        .padding([.horizontal, .bottom])
                    } header: {
                        SectionHeader("Information")
                            .padding([.horizontal, .top])
                            .padding(.bottom, 4.0)
                    }
                    .multilineTextAlignment(.leading)
                }
                .ignoresSafeArea(edges: .top)
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text("Done").fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button(action: openRename) {
                            Label("Rename", systemImage: "character.cursor.ibeam")
                        }

                        NavigationLink {
                            GameManageCollectionsView(game: game)
                        } label: {
                            Label("Manage Collections", systemImage: "square.stack.fill")
                        }

                        ReplaceBoxartMenu(
                            isDatabaseOpen: $isChangeBoxartFromDatabaseOpen,
                            isPhotosOpen: $isChangeBoxartFromPhotosOpen
                        )

                        Divider()

                        Menu {
                            Button(action: importSave) {
                                Label("Import Save", systemImage: "square.and.arrow.down")
                            }
                            Button(action: exportSave) {
                                Label("Export Save", systemImage: "square.and.arrow.up")
                            }
                            Button(action: deleteSave) {
                                Label("Delete Save", systemImage: "trash")
                            }
                        } label: {
                            Label("Manage Save", systemImage: "doc")
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
            .playGameErrorAlert(errorModel: playGameErrorModel)
            .renameItemAlert(
                $renameSaveStateTarget,
                key: \.name,
                title: "Rename State",
                placeholder: "State Name"
            ) { saveState, name in
                Task {
                    try await persistence.library.rename(.init(saveState), to: name)
                }
            }
            .alert("Rename Game", isPresented: self.$isRenameGameOpen) {
                TextField("Game Name", text: self.$renameGameText)
                Button("Cancel", role: .cancel, action: self.renameCancelled)
                Button("Rename", action: self.rename)
            }
            .sheet(isPresented: $isChangeBoxartFromDatabaseOpen) {
                BoxartDatabasePicker(
                    system: game.system,
                    initialQuery: game.name ?? "",
                    finished: self.boxartFromDatabase
                )
            }
            .photosImporter(
                isPresented: $isChangeBoxartFromPhotosOpen,
                onSelection: self.boxartFromPhotos(entry:)
            )
        }
    }

    private func openRename() {
        renameGameText = game.name ?? ""
        isRenameGameOpen = true
    }

    private func rename() {
        Task {
            try await persistence.library.rename(ObjectBox(game), to: renameGameText)
            renameGameText = ""
        }
    }

    private func renameCancelled() {
        renameGameText = ""
    }

    private func delete() {
        Task {
            await MainActor.run {
                dismiss()
            }
            try? await persistence.library.delete(.init(self.game))
        }
    }

    // MARK: Box Art

    private func boxartFromPhotos(entry: Result<URL, any Error>) {
        guard case .success(let url) = entry else { return }
        Task {
            do {
                try await persistence.library.replaceCoverArt(game: .init(game), copying: url)
            } catch {
                // FIXME: present this to the user
                print(error)
            }
        }
    }

    private func boxartFromDatabase(entry: OpenVGDB.Item) {
        guard let url = entry.boxart else { return }
        Task {
            do {
                try await persistence.library.replaceCoverArt(game: .init(game), fromRemote: url)
            } catch {
                // FIXME: present this to the user
                print(error)
            }
        }
    }

    // MARK: Manage Saves

    private func importSave() {}

    private func exportSave() {}

    private func deleteSave() {}

    private func onPlayError(error: PlayGameAction.Failure, game: Game) {
        print(error, game)
    }
}


@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        NavigationStack {
            GameView(game: game)
                .environment(\.playGame, PlayGameAction())
        }
    }
}
