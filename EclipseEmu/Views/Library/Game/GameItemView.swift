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
    @State private var isRenameOpen: Bool = false
    @State private var isDeleteOpen: Bool = false

    @State private var isReplaceRomConfirmationOpen: Bool = false
    @State private var isImportSaveConfirmationOpen: Bool = false
    @State private var isDeleteSaveConfirmationOpen: Bool = false
    
    var body: some View {
        let isSelected = viewModel.selection.contains(game)
        
        Button(action: action) {
            DualLabeledImage(
                title: Text(verbatim: game.name, fallback: "GAME_UNNAMED"),
                subtitle: Text(game.system.string),
                image: game.cover,
                overlayAlignment: .bottomTrailing
            ) {
                checkbox(isSelected: isSelected)
            }
            .contentShape(Rectangle())
            .opacity(viewModel.isSelecting && !isSelected ? 0.5 : 1.0)
        }
        .buttonStyle(.borderless)
        .contextMenu(menuItems: menuItems, preview: preview)
        .renameItem("RENAME_GAME", item: game, isPresented: $isRenameOpen)
        .deleteItem("DELETE_GAME", isPresented: $isDeleteOpen, perform: deleteGame) {
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
    private func checkbox(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(isSelected ? AnyShapeStyle(.selection) : AnyShapeStyle(.background))
            Image(systemName: "checkmark")
                .foregroundStyle(.white)
                .imageScale(.small)
                .frame(width: 24, height: 24)
                .opacity(Double(isSelected))
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(isSelected ? .white.opacity(1) : .gray.opacity(0.8))
        }
        .compositingGroup()
        .frame(width: 24, height: 24)
        .opacity(Double(viewModel.isSelecting))
        .padding(8.0)
    }
    
    @ViewBuilder
    private func menuItems() -> some View {
        ControlGroup {
            Button("PLAY", systemImage: "play.fill", action: play)
            Button("SAVE_STATES", systemImage: "rectangle.stack.badge.play.fill") {
                viewModel.gameSaveStatesTarget = game
            }
        }
        
        ToggleButton("RENAME", systemImage: "text.cursor", value: $isRenameOpen)

        Button("MANAGE_TAGS", systemImage: "tag") {
            viewModel.manageTagsTarget = .one(game)
        }
        
        Menu("REPLACE_COVER_ART", systemImage: "photo") {
            Button("REPLACE_COVER_ART_FROM_DATABASE", systemImage: "cylinder.split.1x2") {
                viewModel.coverPickerMethod = .database(game)
            }
            Button("REPLACE_COVER_ART_FROM_PHOTOS", systemImage: "photo.stack") {
                viewModel.coverPickerMethod = .photos(game)
            }
        }
        
        Divider()

        ToggleButton("REPLACE_ROM", systemImage: "rectangle.2.swap", value: $isReplaceRomConfirmationOpen)
        
        Menu("MANAGE_SAVE", systemImage: "doc") {
            ToggleButton("IMPORT_SAVE", systemImage: "square.and.arrow.down", value: $isImportSaveConfirmationOpen)
            Button("EXPORT_SAVE", systemImage: "square.and.arrow.up", action: exportSave)
            Divider()
            ToggleButton("DELETE_SAVE", systemImage: "trash", role: .destructive, value: $isDeleteSaveConfirmationOpen)
        }
        
        Button("MANAGE_CHEATS", systemImage: "memorychip") {
            viewModel.gameCheatsTarget = game
        }
        Button("SETTINGS", systemImage: "gear") {
            viewModel.gameSettingsTarget = game
        }
        Divider()
        
        ToggleButton("DELETE", systemImage: "trash", role: .destructive, value: $isDeleteOpen)
    }
    
    @ViewBuilder
    private func preview() -> some View {
        DualLabeledImage(
            title: Text(verbatim: game.name, fallback: "GAME_UNNAMED"),
            subtitle: Text(game.system.string),
            image: game.cover,
            idealWidth: 192.0,
            overlayAlignment: .bottomTrailing
        ) {
            EmptyView()
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
        viewModel.selection.toggle(game, if: !viewModel.selection.contains(game))
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
