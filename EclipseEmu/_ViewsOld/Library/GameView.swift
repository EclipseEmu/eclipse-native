import EclipseKit
import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
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
                            DataPointView(title: "SHA-1 Checksum") {
                                Text(verbatim: game.sha1, fallback: "Unknown")
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
                            GameTagsView(game: game)
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
                            Button(role: .destructive, action: deleteSave) {
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
                    try await persistence.objects.rename(.init(saveState), to: name)
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
            try await persistence.objects.rename(ObjectBox(game), to: renameGameText)
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
            try? await persistence.objects.delete(.init(self.game))
        }
    }

    // MARK: Box Art

    private func boxartFromPhotos(entry: Result<URL, any Error>) {
        guard case .success(let url) = entry else { return }
        Task {
            do {
                try await persistence.objects.replaceCoverArt(game: .init(game), copying: url)
            } catch {
                // FIXME: present this to the user
                print(error)
            }
        }
    }

    private func boxartFromDatabase(entry: OpenVGDBItem) {
        guard let url = entry.cover else { return }
        Task {
            do {
                try await persistence.objects.replaceCoverArt(game: .init(game), fromRemote: url)
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

    private func onPlayError(error: PlayGameError, game: Game) {
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
