import SwiftUI
import CoreData
import UniformTypeIdentifiers
import EclipseKit

struct LibraryView: View {
    static let romFileTypes: [UTType] = [
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gb"),
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gbc"),
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gba"),
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.nes"),
        UTType(exportedAs: "dev.magnetar.eclipseemu.rom.snes"),
    ]

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.persistenceCoordinator) private var persistence
    @Environment(\.playGame) private var playGame
    @StateObject var viewModel: GameListViewModel = .init(filter: .none)

    @State var isRomPickerOpen: Bool = false
    @State var isErrorDialogOpen = false
    @State var error: GameManager.Failure?

    @FetchRequest(
        fetchRequest: GameManager.recentlyPlayedRequest(),
        animation: .default)
    private var recentlyPlayed: FetchedResults<Game>
    
    var body: some View {
        CompatNavigationStack {
            ScrollView {
                Section {
                    GameKeepPlayingScroller(games: recentlyPlayed, viewModel: viewModel)
                } header: {
                    SectionHeader("Keep Playing")
                        .padding([.horizontal, .top])
                }
                .isHidden(
                    viewModel.isSelecting ||
                    recentlyPlayed.isEmpty ||
                    !viewModel.searchQuery.isEmpty
                )

                Section {
                    GameList(viewModel: viewModel)
                } header: {
                    SectionHeader("All Games")
                        .padding([.horizontal, .top])
                        .padding(.bottom, -8)
                }
            }
            .allowsHitTesting(!viewModel.isEmpty)
            .opacity(Double(!viewModel.isEmpty))
            .overlay {
                EmptyGameListMessage(filter: viewModel.filter)
                    .opacity(Double(viewModel.isEmpty))
                    .allowsHitTesting(false)
            }
            .searchable(text: $viewModel.searchQuery)
            .alert(isPresented: $isErrorDialogOpen, error: self.error) {}
            .fileImporter(
                isPresented: $isRomPickerOpen,
                allowedContentTypes: Self.romFileTypes,
                onCompletion: self.fileImported
            )
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem {
                    if !viewModel.isSelecting {
                        Menu {
                            GameListMenuItems(viewModel: viewModel)
                        } label: {
                            Label("List Options", systemImage: "ellipsis.circle")
                        }
                    }
                }

                ToolbarItem {
                    if !viewModel.isSelecting {
                        Button {
                            self.isRomPickerOpen = true
                        } label: {
                            Label("Add Game", systemImage: "plus")
                        }
                    }
                }

                #if !os(macOS)
                GameListToolbarItems(viewModel: viewModel)
                #endif
            }
            .sheet(item: $viewModel.target) { game in
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
                    return await self.reportError(error: .failedToGetReadPermissions)
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
                
                let system = if let fileType {
                    GameSystem.from(fileType: fileType)
                } else {
                    GameSystem.unknown
                }
                
                guard system != .unknown else {
                    return await self.reportError(error: .unknownFileType)
                }
                
                let (name, romExtension) = url.fileNameAndExtension()
                
                do {
                    try await GameManager.insert(
                        name: name,
                        system: system,
                        romPath: url,
                        romExtension: romExtension,
                        in: persistence
                    )
                } catch {
                    return await self.reportError(error: .unknownFileType)
                }
            }
            break
        case .failure(let err):
            print(err)
            break
        }
    }
    
    @MainActor
    func reportError(error: GameManager.Failure) {
        self.error = error
        self.isErrorDialogOpen = true
    }
}

#if DEBUG
#Preview {
    let persistence = PersistenceCoordinator.preview
    let viewContext = persistence.context

    for i in 0..<5 {
        let game = Game(context: viewContext)
        game.name = "Game \(i)"
        game.system = .gba
        game.id = UUID()
        game.md5 = ""
        game.datePlayed = Date.now
        game.dateAdded = Date.now
    }

    return LibraryView()
        .environment(\.managedObjectContext, viewContext)
        .environment(\.persistenceCoordinator, persistence)
}
#endif
