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
    @State var searchQuery: String = ""
    @State var selectedGame: Game? = nil
    @State var isRomPickerOpen: Bool = false
    @State var isSettingsOpen = false
    @State var isCreateCollectionOpen = false
    @State var isErrorDialogOpen = false
    @State var error: GameManager.Failure?

    @FetchRequest(
        fetchRequest: GameManager.recentlyPlayedRequest(),
        animation: .default)
    private var recentlyPlayed: FetchedResults<Game>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GameCollection.name, ascending: true)],
        animation: .default)
    private var collections: FetchedResults<GameCollection>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Game.name, ascending: true)],
        animation: .default)
    private var games: FetchedResults<Game>
    
    var body: some View {
        CompatNavigationStack {
            ScrollView {
                if searchQuery.isEmpty {
                    Section {
                        GameKeepPlayingScroller(games: recentlyPlayed, selectedGame: $selectedGame)
                            .emptyMessage(recentlyPlayed.isEmpty) {
                                Text("No Played Games")
                            } message: {
                                Text("As you play games, they'll show up here so you can quickly jump back in.")
                            }
                    } header: {
                        SectionHeader("Keep Playing")
                            .padding([.horizontal, .top])
                    }
                    .isHidden(games.isEmpty)
                    
                    Section {
                        GameCollectionGrid(collections: collections)
                            .padding([.horizontal, .bottom])
                    } header: {
                        SectionHeader("Collections").padding([.horizontal, .top])
                    }
                    .isHidden(collections.isEmpty)
                }

                Section {
                    GameGrid(games: self.games, selectedGame: $selectedGame)
                        .padding([.horizontal, .bottom])
                        .emptyMessage(self.games.isEmpty) {
                            Text("No Games")
                        } message: {
                            Text("You haven't added any games to your library. Use the \(Image(systemName: "plus")) button to add games.")
                        }
                } header: {
                    SectionHeader("All Games") {
                        Menu {
                            Menu("Sort") {
                                Text("Name")
                                Text("Date Added")
                            }
                        } label: {
                            Label("Sort & Filter", systemImage: "line.3.horizontal.decrease")
                        }
                        .labelStyle(.iconOnly)
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .fixedSize()
                    }
                    .padding([.horizontal, .top])
                }
            }
            .alert(isPresented: $isErrorDialogOpen, error: self.error) {}
            .searchable(text: $searchQuery)
            .onChange(of: searchQuery) { newValue in
                games.nsPredicate = newValue.isEmpty 
                    ? nil
                    : NSPredicate(format: "name CONTAINS %@", newValue)
            }
            .fileImporter(isPresented: $isRomPickerOpen, allowedContentTypes: Self.romFileTypes, onCompletion: self.fileImported)
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        self.isSettingsOpen = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem {
                    Menu {
                        Button {
                            self.isRomPickerOpen = true
                        } label: {
                            Label("Game", systemImage: "app.dashed")
                        }
                        Button {
                            self.isCreateCollectionOpen = true
                        } label: {
                            Label("Collection", systemImage: "square.on.square")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $selectedGame) { game in
                GameView(game: game)
                #if os(macOS)
                    .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
                #endif
            }
            .sheet(isPresented: $isSettingsOpen) {
                SettingsView()
                #if os(macOS)
                    .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
                #endif
            }
            .sheet(isPresented: $isCreateCollectionOpen) {
                EditCollectionView()
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
                
                let fileName = url.lastPathComponent
                
                var name = fileName
                var romExtension: String?
                
                let fileExtensionIndex = fileName.firstIndex(of: ".")
                if let fileExtensionIndex {
                    name = String(fileName.prefix(upTo: fileExtensionIndex))
                    romExtension = String(fileName[fileExtensionIndex...])
                }
                
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
    LibraryView()
        .environment(\.managedObjectContext, PersistenceCoordinator.preview.container.viewContext)
}
#endif
