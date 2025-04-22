import SwiftUI
import UniformTypeIdentifiers
import OSLog

private enum GameViewError: LocalizedError {
    case saveFileDoesNotExist
    case playbackError(GamePlaybackError)

    case saveFileImport(any Error)
    case saveFileExport(any Error)
    case saveFileDelete(FileSystemError)
    case replaceROM(any Error)

    case unknown(any Error)

    var errorDescription: String? {
        return switch self {
        case .playbackError(let error): error.errorDescription ?? error.localizedDescription
        case .saveFileDoesNotExist: "The save file does not exist."
        case .saveFileDelete(let error):
            "An error occurred while deleting the save: \(error.errorDescription ?? error.localizedDescription)"
        case .saveFileImport(let error):
            "An error occurred while importing the save: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        case .saveFileExport(let error):
            "An error occurred while exporting the save: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        case .replaceROM(let error):
            "An error occurred while replacing the ROM: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        case .unknown(let error):
            "An unknown error occurred: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        }
    }
}

private struct SaveFileDocument: FileDocument {
    static let readableContentTypes = [UTType.save]
    let data: URL
    let fileName: String?

    private struct EmptyError: Error {}

    init(url: URL, fileName: String) {
        self.data = url
        self.fileName = fileName
    }

    init(configuration: ReadConfiguration) throws {
        throw EmptyError()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let wrapper = try FileWrapper(url: data)
        wrapper.preferredFilename = self.fileName
        return wrapper
    }
}

private struct HeaderBackground: View {
    private let coordinateSpace: CoordinateSpace
    private let color: Color

    init(in coordinateSpace: CoordinateSpace, color: Color) {
        self.coordinateSpace = coordinateSpace
        self.color = color
    }

    var body: some View {
        GeometryReader { geo in
            let outer = geo.frame(in: coordinateSpace)
            let minY = outer.minY

            Rectangle()
                .foregroundStyle(Material.ultraThick)
                .background(Color.black.gradient.opacity(0.5))
                .background(color)
                .offset(y: -geo.safeAreaInsets.top + minY > 0 ? -minY : -geo.safeAreaInsets.top)
                .transformEffect(.init(scaleX: 1.0, y: 1.0 + (minY > 0 ? minY / (geo.size.height - minY) : 0)))
                .overlay(alignment: .bottom) {
                    Divider()
                }
        }
    }
}

struct GameView: View {
    private let dateFormatter = RelativeDateTimeFormatter()

    @EnvironmentObject private var playback: GamePlayback
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ObservedObject var game: GameObject
    @FetchRequest<SaveStateObject>(fetchRequest: SaveStateObject.fetchRequest())
    private var saveStates: FetchedResults<SaveStateObject>
    @State private var coverColor: Color?

    @State private var renameTarget: GameObject?
    @State private var deleteTarget: GameObject?
    @State private var renameSaveStateTarget: SaveStateObject?
    @State private var deleteSaveStateTarget: SaveStateObject?
    @State private var coverPickerMethod: CoverPickerMethod?
    @State private var isManageTagsOpen: Bool = false
    @State private var fileImportRequest: FileImportType?

    @State private var isReplaceRomConfirmationOpen = false
    @State private var isImportSaveConfirmationOpen = false
    @State private var isDeleteSavePresented: Bool = false
    @State private var exportedSaveFile: SaveFileDocument?

    @State private var error: GameViewError?

    init(game: GameObject, coverColor: Color = .clear) {
        self.game = game

        let request = SaveStateObject.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SaveStateObject.isAuto, ascending: false),
            NSSortDescriptor(keyPath: \SaveStateObject.date, ascending: false)
        ]
        request.fetchLimit = 10

        self._saveStates = .init(fetchRequest: request)
    }

    private var headerSection: some View {
        VStack {
            AverageColorLocalImage(game.cover, color: $coverColor) { image in
                image
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8.0)
                    .foregroundStyle(.secondary)
            }
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 256.0)

            Text(verbatim: game.name, fallback: "GAME_UNNAMED")
                .padding(.top)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(game.system.string)
                .padding(.bottom)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: play) {
                Label("PLAY_GAME", systemImage: "play.fill").fontWeight(.semibold)
            }
            .tint(.white)
            .foregroundStyle(.black)
            .tint(.accentColor)
            .buttonStyle(.borderedProminent)
            .modify {
                if #available(macOS 14, *) {
                    $0.buttonBorderShape(.capsule)
                } else {
                    $0
                }
            }
            .controlSize(.large)
        }
        .frame(minWidth: .zero, maxWidth: .infinity)
        .padding(.vertical, 32.0)
    }

    private var saveStatesSection: some View {
        Section {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 16.0) {
                    ForEach(saveStates) { saveState in
                        SaveStateItem(
                            saveState,
                            title: .name,
                            formatter: dateFormatter,
                            renameTarget: $renameSaveStateTarget,
                            deleteTarget: $deleteSaveStateTarget,
                            action: saveStateSelected
                        )
                        .frame(height: 226.0)
                    }
                }
                .padding([.bottom, .horizontal])
            }
            .buttonStyle(.plain)
            .emptyState(saveStates.isEmpty) {
                EmptyMessage {
                    Text("NO_SAVE_STATES_TITLE")
                } message: {
                    Text("NO_SAVE_STATES_MESSAGE")
                }
                .padding(.bottom)
            }
        } header: {
            HStack {
                Text("SAVE_STATES")
                    .sectionHeaderStyle()

                Spacer()

                NavigationLink(to: .saveStates(game)) {
                    Text("VIEW_ALL")
                        .font(.body)
                }
            }
            .padding([.horizontal, .top])
        }
    }

    var informationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12.0) {
                DataPointView(title: "GAME_DATE_ADDED") {
                    Text(game.dateAdded, format: .dateTime, fallback: "UNKNOWN")
                }
                DataPointView(title: "GAME_LAST_PLAYED") {
                    Text(game.datePlayed, format: .dateTime, fallback: "NEVER")
                }
                DataPointView(title: "GAME_SHA1_CHECKSUM") {
                    Text(verbatim: game.sha1, fallback: "UNKNOWN")
                        .font(.caption.monospaced())
                }
            }
            .padding([.horizontal, .bottom])
        } header: {
            Text("INFORMATION")
                .sectionHeaderStyle()
                .padding(.horizontal)
                .padding(.bottom, 4.0)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                headerSection
                    .padding(.top, proxy.safeAreaInsets.top)
                    .background(HeaderBackground(in: .named("scrollView"), color: coverColor ?? .white))
                    .ignoresSafeArea(edges: [.leading, .trailing])
                saveStatesSection
                informationSection
            }
            .coordinateSpace(name: "scrollView")
            .ignoresSafeArea(edges: .top)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar { toolbarContent }
        .sheet(isPresented: $isManageTagsOpen) {
            NavigationStack {
                ManageTagsView(target: .one(game))
            }
        }
        .renameItem("RENAME_GAME", item: $renameTarget)
        .deleteItem("DELETE_GAME", item: $deleteTarget, dismiss: true) { game in
            Text("DELETE_GAME_MESSAGE \(game.name ?? String(localized: "GAME_UNNAMED"))")
        }
        .renameItem("RENAME_SAVE_STATE", item: $renameSaveStateTarget)
        .deleteItem("DELETE_SAVE_STATE", item: $deleteSaveStateTarget) { saveState in
            Text("DELETE_SAVE_STATE_MESSAGE \(saveState.name ?? String(localized: "SAVE_STATE_UNNAMED"))")
        }
        .confirmationDialog("REPLACE_ROM", isPresented: $isReplaceRomConfirmationOpen) {
            Button("CANCEL", role: .cancel) {}
            Button("OK", action: self.replaceROM)
        } message: {
            Text("REPLACE_ROM_MESSAGE")
        }
        .confirmationDialog("IMPORT_SAVE", isPresented: $isImportSaveConfirmationOpen) {
            Button("CANCEL", role: .cancel) {}
            Button("OK", action: self.importSave)
        } message: {
            Text("IMPORT_SAVE_MESSAGE")
        }
        .deleteItem(
            "DELETE_SAVE",
            isPresented: $isDeleteSavePresented,
            perform: deleteSave
        ) {
            Text("DELETE_SAVE_MESSAGE")
        }
        .coverPicker(presenting: $coverPickerMethod)
        .multiFileImporter($fileImportRequest)
        .fileExporter(
            isPresented: .isSome($exportedSaveFile),
            document: exportedSaveFile,
            contentType: .save,
            defaultFilename: exportedSaveFile?.fileName,
            onCompletion: saveFileExported
        )
        .alert(isPresented: .isSome($error), error: error) {
            errorAlertActions
        }
    }

    var toolbarContent: some View {
        Menu {
            Button(action: rename) {
                Label("RENAME", systemImage: "text.cursor")
            }

            CoverPickerMenu(game: game, coverPickerMethod: $coverPickerMethod)

            Divider()

            Button(action: manageTags) {
                Label("MANAGE_TAGS", systemImage: "tag")
            }

            NavigationLink(to: .cheats(game)) {
                Label("MANAGE_CHEATS", systemImage: "memorychip")
            }

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
                ToggleButton(role: .destructive, value: $isDeleteSavePresented) {
                    Label("DELETE_SAVE", systemImage: "trash")
                }
            } label: {
                Label("MANAGE_SAVE", systemImage: "doc")
                    .labelStyle(.iconOnly)
            }

            Divider()

            Button(role: .destructive, action: delete) {
                Label("DELETE", systemImage: "trash")
            }
        } label: {
            Label("OPTIONS", systemImage: "ellipsis.circle")
        }
    }

    @ViewBuilder
    var errorAlertActions: some View {
        switch error {
        case .playbackError(let playbackError):
            switch playbackError {
            case .hashMismatch(let file, let hash, let url):
                Button("CANCEL", role: .cancel) {}
                switch file {
                case .rom:
                    Button("REPLACE_ANYWAYS", role: .destructive) {
                        self.resolveHashMismatch(newHash: hash, sourceURL: url)
                    }
                default: EmptyView()
                }
            case .missingFile(let file):
                switch file {
                case .rom, .saveState:
                    Button("CANCEL", role: .cancel) {}
                    Button("SELECT_FILE", action: replaceROM)
                default:
                    Button("OK") {}
                }
            default:
                Button("OK") {}
            }
        default:
            Button("OK") {}
        }
    }

    private func delete() {
        self.deleteTarget = self.game
    }

    private func rename() {
        self.renameTarget = self.game
    }

    private func manageTags() {
        self.isManageTagsOpen = true
    }

    private func play() {
        Task {
            do {
                try await playback.play(game: game, persistence: persistence)
            } catch {
                self.error = .playbackError(error as! GamePlaybackError)
            }
        }
    }

    private func saveStateSelected(saveState: SaveStateObject) {
        Task {
            do {
                try await playback.play(state: saveState, persistence: persistence)
            } catch {
                self.error = .playbackError(error as! GamePlaybackError)
            }
        }
    }
}

// MARK: ROM Management

extension GameView {
    private func replaceROM() {
        guard let fileType = game.system.fileType else { return}
        self.fileImportRequest = .init(types: [fileType], allowsMultipleSelection: false, completion: romFileImported)
    }

    private nonisolated func romFileImported(_ result: Result<[URL], any Error>) {
        Task {
            do {
                let (game, sha1, destinationPath) = await MainActor.run {
                    (ObjectBox(self.game), self.game.sha1, self.game.romPath)
                }

                guard let sourceURL = try result.get().first, let expectedHash = sha1 else { return }

                let doStopAccessing = sourceURL.startAccessingSecurityScopedResource()
                defer {
                    if doStopAccessing {
                        sourceURL.stopAccessingSecurityScopedResource()
                    }
                }

                let actualHash = try await persistence.files.sha1(for: sourceURL)

                guard expectedHash == actualHash else {
                    throw GameViewError.playbackError(.hashMismatch(.rom(game), actualHash, sourceURL))
                }

                try await persistence.files.overwrite(copying: .other(sourceURL), to: destinationPath)
            } catch let error as GameViewError {
                await MainActor.run {
                    self.error = error
                }
            } catch {
                await MainActor.run {
                    self.error = .replaceROM(error)
                }
            }
        }
    }

    @MainActor
    private func resolveHashMismatch(newHash: String, sourceURL: URL) {
        Task {
            do {
                let doStopAccessing = sourceURL.startAccessingSecurityScopedResource()
                defer {
                    if doStopAccessing {
                        sourceURL.stopAccessingSecurityScopedResource()
                    }
                }

                if let oldPath = self.game.sha1, await persistence.objects.canDeleteRom(sha1: oldPath) {
                    try? await persistence.files.delete(at: self.game.romPath)
                }

                let fileExtension = sourceURL.fileExtension()
                try await persistence.objects.updateHash(newHash, for: .init(game))
                try await persistence.files.overwrite(copying: .other(sourceURL), to: .rom(fileName: newHash, fileExtension: fileExtension))
            } catch {
                self.error = .replaceROM(error)
            }
        }
    }
}

// MARK: Save Management

extension GameView {
    private func importSave() {
        self.fileImportRequest = .saves(completion: saveFileImported)
    }

    private func exportSave() {
        Task {
            let url = persistence.files.url(for: game.savePath)
            self.exportedSaveFile = SaveFileDocument(url: url, fileName: "\(game.name ?? "Game") \(Date())")
        }
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

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        NavigationStack {
            GameView(game: game, coverColor: Color.red)
        }
    }
}
