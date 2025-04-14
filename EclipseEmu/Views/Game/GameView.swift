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

            Text(game.name ?? "Game")
                .padding(.top)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(game.system.string)
                .padding(.bottom)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: play) {
                Label("Play Game", systemImage: "play.fill").fontWeight(.semibold)
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
                    Text("No Save States")
                } message: {
                    Text("You haven't made any save states for this game yet.")
                }
                .padding(.bottom)
            }
        } header: {
            HStack {
                Text("Save States")
                    .sectionHeaderStyle()

                Spacer()

                NavigationLink(to: .saveStates(game)) {
                    Text("View All")
                        .font(.body)
                }
            }
            .padding([.horizontal, .top])
        }
    }

    var informationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12.0) {
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
            Text("Information")
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
        .renameItem("Rename Game", item: $renameTarget)
        .deleteItem("Delete Game", item: $deleteTarget, dismiss: true) { game in
            Text("Are you sure you want to delete \(game.name ?? "this game")? Its saves, save states, and cover art will all be deleted. This can't be undone.")
        }
        .renameItem("Rename Save State", item: $renameSaveStateTarget)
        .deleteItem("Delete Save State", item: $deleteSaveStateTarget) { saveState in
            Text("Are you sure you want to delete \(saveState.name ?? "this save state")? This can't be undone.")
        }
        .confirmationDialog("Replace ROM", isPresented: $isReplaceRomConfirmationOpen) {
            Button("Cancel", role: .cancel) {}
            Button("OK", action: self.replaceROM)
        } message: {
            Text("By replacing the ROM, you will overwrite the existing ROM for this game. This may cause issues with save and save state compatibility and cannot be undone.")
        }
        .confirmationDialog("Import Save", isPresented: $isImportSaveConfirmationOpen) {
            Button("Cancel", role: .cancel) {}
            Button("OK", action: self.importSave)
        } message: {
            Text("By importing a save, you will overwrite any existing save for this game. This cannot be undone.")
        }
        .deleteItem(
            "Delete Save",
            isPresented: $isDeleteSavePresented,
            perform: deleteSave
        ) {
            Text("Are you sure you want to delete this game's save file? This can't be undone.")
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
                Label("Rename", systemImage: "text.cursor")
            }

            CoverPickerMenu(game: game, coverPickerMethod: $coverPickerMethod)

            Divider()

            Button(action: manageTags) {
                Label("Manage Tags", systemImage: "tag")
            }

            NavigationLink(to: .cheats(game)) {
                Label("Manage Cheats", systemImage: "memorychip")
            }

            Divider()

            ToggleButton(value: $isReplaceRomConfirmationOpen) {
                Label("Replace ROM", systemImage: "rectangle.2.swap")
            }
            Menu {
                ToggleButton(value: $isImportSaveConfirmationOpen) {
                    Label("Import Save", systemImage: "square.and.arrow.down")
                }
                Button(action: exportSave) {
                    Label("Export Save", systemImage: "square.and.arrow.up")
                }
                Divider()
                ToggleButton(role: .destructive, value: $isDeleteSavePresented) {
                    Label("Delete Save", systemImage: "trash")
                }
            } label: {
                Label("Manage Save", systemImage: "doc")
                    .labelStyle(.iconOnly)
            }

            Divider()

            Button(role: .destructive, action: delete) {
                Label("Remove", systemImage: "trash")
            }
        } label: {
            Label("Options", systemImage: "ellipsis.circle")
        }
    }

    @ViewBuilder
    var errorAlertActions: some View {
        switch error {
        case .playbackError(let playbackError):
            switch playbackError {
            case .hashMismatch(let file, let hash, let url):
                Button("Cancel", role: .cancel) {}
                switch file {
                case .rom:
                    Button("Replace Anyways", role: .destructive) {
                        self.resolveHashMismatch(newHash: hash, sourceURL: url)
                    }
                default: EmptyView()
                }
            case .missingFile(let file):
                switch file {
                case .rom, .saveState:
                    Button("Cancel", role: .cancel) {}
                    Button("Select File", action: replaceROM)
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
