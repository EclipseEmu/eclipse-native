import SwiftUI
import EclipseKit
import OSLog

struct GameItemView: View {
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var playback: GamePlayback
    @EnvironmentObject private var coreRegistry: CoreRegistry

    @ObservedObject var game: GameObject
    @ObservedObject var viewModel: LibraryViewModel
    
    @State private var error: GameViewError?
    @State private var isRenameGameConfirmationOpen: Bool = false
    @State private var isDeleteGameConfirmationOpen: Bool = false

    @State private var isReplaceRomConfirmationOpen: Bool = false
    @State private var isImportSaveConfirmationOpen: Bool = false
    @State private var isDeleteSaveConfirmationOpen: Bool = false

    var isSelected: Bool {
        viewModel.selection.contains(game)
    }
    
    var body: some View {
        let isSelected = self.isSelected
        
        Button(action: action) {
            DualLabeledImage(
                title: Text(verbatim: game.name, fallback: "GAME_UNNAMED"),
                subtitle: Text(game.system.string)
            ) {
                CoverArtView(game.cover)
                    .overlay(alignment: .bottomTrailing) {
                        GameItemCheckbox(isSelected: isSelected)
                            .opacity(Double(viewModel.isSelecting))
                            .padding(8.0)
                    }
            }
            .contentShape(Rectangle())
            .opacity(viewModel.isSelecting && !isSelected ? 0.5 : 1.0)
        }
        .buttonStyle(.borderless)
        .contextMenu(menuItems: menuItems, preview: preview)
        .renameItem("RENAME_GAME", isPresented: $isRenameGameConfirmationOpen, perform: renameGame)
        .deleteItem("DELETE_GAME", isPresented: $isDeleteGameConfirmationOpen, perform: deleteGame) {
            Text("DELETE_GAME_MESSAGE \(game.name ?? String(localized: "GAME_UNNAMED"))")
        }
        .deleteItem("DELETE_SAVE", isPresented: $isDeleteSaveConfirmationOpen, perform: deleteSave) {
            Text("DELETE_SAVE_MESSAGE")
        }
        .gameErrorHandler(
            game: game,
            error: $error,
            fileImportRequest: $viewModel.fileImportRequest,
            isReplaceRomConfirmationOpen: $isReplaceRomConfirmationOpen
        )
        .confirmationDialog("IMPORT_SAVE", isPresented: $isImportSaveConfirmationOpen) {
            Button("CANCEL", role: .cancel) {}
            Button("OK", action: self.importSave)
        } message: {
            Text("IMPORT_SAVE_MESSAGE")
        }
    }
    
    @ViewBuilder
    private func menuItems() -> some View {
        Button(action: play) {
            Label("PLAY", systemImage: "play")
        }
        Button {
            viewModel.gameSaveStatesTarget = game
        } label: {
            Label("SAVE_STATES", systemImage: "rectangle.stack.badge.play")
        }
        
        Divider()
        
        ToggleButton(value: $isRenameGameConfirmationOpen) {
            Label("RENAME", systemImage: "text.cursor")
        }

        Button {
            viewModel.manageTagsTarget = .one(game)
        } label: {
            Label("MANAGE_TAGS", systemImage: "tag")
        }
        
        CoverPickerMenu(game: game, coverPickerMethod: $viewModel.coverPickerMethod)
        
        Divider()

        ToggleButton(value: $isReplaceRomConfirmationOpen) {
            Label("REPLACE_ROM", systemImage: "rectangle.2.swap")
        }
        
        Menu {
            ToggleButton(value: $isImportSaveConfirmationOpen) {
                Label("IMPORT_SAVE", systemImage: "square.and.arrow.down")
            }
            Button(action: exportSave) {
                Label("EXPORT_SAVE", systemImage: "square.and.arrow.up")
            }
            Divider()
            ToggleButton(role: .destructive, value: $isDeleteSaveConfirmationOpen) {
                Label("DELETE_SAVE", systemImage: "trash")
            }
        } label: {
            Label("MANAGE_SAVE", systemImage: "doc")
        }
        
        Button {
            viewModel.gameCheatsTarget = game
        } label: {
            Label("MANAGE_CHEATS", systemImage: "memorychip")
        }
        Button {
            viewModel.gameSettingsTarget = game
        } label: {
            Label("SETTINGS", systemImage: "gear")
        }
        Divider()
        
        ToggleButton(role: .destructive, value: $isDeleteGameConfirmationOpen) {
            Label("DELETE", systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private func preview() -> some View {
        VStack(spacing: 12.0) {
            CoverArtView(game.cover)
                .frame(minWidth: 0, idealWidth: 192.0, maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading) {
                Text(verbatim: game.name, fallback: "GAME_UNNAMED")
                    .font(.footnote)
                    .lineLimit(1)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Text(game.system.string)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .environmentObject(persistence)
    }
    
    private func action() {
        if viewModel.isSelecting {
            toggleSelection()
        } else {
            play()
        }
    }
    
    private func play() {
        Task {
            do {
                try await playback.play(game: game, persistence: persistence, coreRegistry: coreRegistry)
            } catch {
                self.error = .playbackError(error as! GamePlaybackError)
            }
        }
    }

    private func toggleSelection() {
        viewModel.selection.toggle(game, if: !isSelected)
    }
    
    private func renameGame(newName: String) {
        Task {
            do {
                try await persistence.objects.rename(.init(game), to: newName)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }

    private func deleteGame() async {
        viewModel.selection.remove(game)
        do {
            try await persistence.objects.delete(.init(game))
        } catch {
            // FIXME: Surface error
            print(error)
        }
    }
}

// MARK: Save Management

extension GameItemView {
    private func importSave() {
        viewModel.fileImportRequest = .saves(completion: saveFileImported)
    }

    private func exportSave() {
        let url = persistence.files.url(for: game.savePath)
        let document = SaveFileDocument(url: url, fileName: "\(game.name ?? "Game") \(Date())")
        viewModel.fileExportRequest = .init(document: document, callback: self.saveFileExported)
    }

    private func deleteSave() async {
        do {
            try await persistence.files.delete(at: game.savePath)
        } catch .fileNoSuchFile {} catch {
            self.error = .saveFileDelete(error)
        }
    }

    private nonisolated func saveFileImported(_ result: Result<[URL], any Error>) {
        Task {
            do {
                guard let sourceURL = try result.get().first else { return }
                let destinationPath = await MainActor.run { game.savePath }
                let doStopAccessing = sourceURL.startAccessingSecurityScopedResource()
                defer {
                    if doStopAccessing {
                        sourceURL.stopAccessingSecurityScopedResource()
                    }
                }

                try await persistence.files.overwrite(copying: .other(sourceURL), to: destinationPath)
            } catch {
                await MainActor.run {
                    self.error = .saveFileImport(error)
                }
            }
        }
    }

    private nonisolated func saveFileExported(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            Logger.fs.info("exported save file to \(url)")
        } catch let error as CocoaError where error.code == .fileNoSuchFile || error.code == .fileReadNoSuchFile  {
            Task { @MainActor in
                self.error = .saveFileDoesNotExist
            }
        } catch {
            Task { @MainActor in
                self.error = .saveFileExport(error)
            }
        }
    }
}


@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    @Previewable @StateObject var viewModel: LibraryViewModel = .init()
    
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        GameItemView(game: game, viewModel: viewModel)
            .frame(maxWidth: 192.0)
    }
    .environmentObject(Settings())
    .environmentObject(CoreRegistry())
}
