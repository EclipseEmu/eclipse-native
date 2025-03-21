import CoreData
import EclipseKit
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    static let recentlyPlayedRequest: NSFetchRequest<Game> = {
        let request = Game.fetchRequest()
        request.fetchLimit = 10
        request.predicate = NSPredicate(format: "datePlayed != nil")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Game.datePlayed, ascending: false)
        ]
        return request
    }()

    enum Failure: LocalizedError {
        case gameManager(GameError)
        case playAction(PlayGameAction.Failure)
    }

    static let romFileTypes: [UTType] = [
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gb"),
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gbc"),
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gba"),
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.nes"),
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.snes")
    ]

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.playGame) private var playGame
    @StateObject var viewModel: GameListViewModel = .init(filter: .none)

    @State var isRomPickerOpen: Bool = false
    @State var isErrorDialogOpen = false
    @State var error: Self.Failure?

    @FetchRequest(
        fetchRequest: Self.recentlyPlayedRequest,
        animation: .default
    )
    private var recentlyPlayed: FetchedResults<Game>

    var body: some View {
        NavigationStack {
            ScrollView {
                Section {
                    GameKeepPlayingScroller(
                        games: self.recentlyPlayed,
                        viewModel: self.viewModel,
                        onPlayError: onPlayFailure
                    )
                } header: {
                    SectionHeader("Keep Playing")
                        .padding([.horizontal, .top])
                }
                .isHidden(
                    self.viewModel.isSelecting ||
                        self.recentlyPlayed.isEmpty ||
                        !self.viewModel.searchQuery.isEmpty
                )

                Section {
                    GameList(viewModel: self.viewModel)
                } header: {
                    SectionHeader("All Games")
                        .padding([.horizontal, .top])
                        .padding(.bottom, -8)
                }
            }
            .allowsHitTesting(!self.viewModel.isEmpty)
            .opacity(Double(!self.viewModel.isEmpty))
            .overlay {
                EmptyGameListMessage(filter: self.viewModel.filter)
                    .opacity(Double(self.viewModel.isEmpty))
                    .allowsHitTesting(false)
            }
            .searchable(text: self.$viewModel.searchQuery)
            .alert(isPresented: self.$isErrorDialogOpen, error: self.error) {
                Button("Cancel", role: .cancel) {}
            }
            .fileImporter(
                isPresented: self.$isRomPickerOpen,
                allowedContentTypes: Self.romFileTypes,
                onCompletion: self.fileImported
            )
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem {
                    if !self.viewModel.isSelecting {
                        Button {
                            self.isRomPickerOpen = true
                        } label: {
                            Label("Add Game", systemImage: "plus")
                        }
                    }
                }

                ToolbarItem {
                    if !self.viewModel.isSelecting {
                        Menu {
                            GameListMenuItems(viewModel: self.viewModel)
                        } label: {
                            Label("List Options", systemImage: "ellipsis.circle")
                        }
                    }
                }

                #if !os(macOS)
                GameListToolbarItems(viewModel: self.viewModel)
                #endif
            }
            .sheet(item: self.$viewModel.target) { game in
                GameView(game: game)
                #if os(macOS)
                    .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
                #endif
            }
        }
    }

    func fileImported(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task.detached(priority: .userInitiated) {
                guard url.startAccessingSecurityScopedResource() else {
                    return await self.reportError(error: .gameManager(.failedToGetReadPermissions))
                }
                defer { url.stopAccessingSecurityScopedResource() }

                let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType

                let system = if let fileType {
                    GameSystem.from(fileType: fileType)
                } else {
                    GameSystem.unknown
                }

                guard system != .unknown else {
                    return await self.reportError(error: .gameManager(.unknownFileType))
                }

                let (name, romExtension) = url.fileNameAndExtension()

                do {
                    try await persistence.library.createGame(
                        name: name,
                        system: system,
                        romPath: url,
                        romExtension: romExtension
                    )

//                    try await GameManager.insert(
//                        name: name,
//                        system: system,
//                        romPath: url,
//                        romExtension: romExtension,
//                        in: self.persistence
//                    )
                } catch {
                    return await self.reportError(error: .gameManager(.unknownFileType))
                }
            }
        case .failure(let err):
            print(err)
        }
    }

    func onPlayFailure(error: PlayGameAction.Failure, game: Game) {
        print(error, game)
        self.reportError(error: .playAction(error))
    }

    @MainActor
    func reportError(error: Self.Failure) {
        self.error = error
        self.isErrorDialogOpen = true
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    LibraryView()
}

