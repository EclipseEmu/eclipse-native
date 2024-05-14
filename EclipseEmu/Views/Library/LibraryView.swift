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
    
    static let recentlyPlayedRequest = {
        let request = Game.fetchRequest()
        request.fetchLimit = 10
        request.predicate = NSPredicate(format: "datePlayed != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Game.datePlayed, ascending: false)]
        return request
    }()
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.persistenceCoordinator) private var persistence
    @Environment(\.playGame) private var playGame
    @State var searchQuery: String = ""
    @State var selectedGame: Game? = nil
    @State var isRomPickerOpen: Bool = false
    @State var isSettingsOpen = false
    @State var isUnknownSystemDialogShown = false
    @State var isTargeted = false
    
    @FetchRequest(
        fetchRequest: Self.recentlyPlayedRequest,
        animation: .default)
    private var recentlyPlayed: FetchedResults<Game>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Game.name, ascending: true)],
        animation: .default)
    private var games: FetchedResults<Game>
    
    var body: some View {
        CompatNavigationStack {
            ScrollView {
                if recentlyPlayed.count != 0 {
                    VStack(alignment: .leading, spacing: 0.0) {
                        SectionHeader(title: "Keep Playing")
                            .padding([.horizontal, .top])
                        
                        ScrollView(.horizontal) {
                            LazyHStack(alignment: .top, spacing: 16.0) {
                                ForEach(recentlyPlayed) { item in
                                    GameKeepPlayingItem(game: item, selectedGame: $selectedGame)
                                }
                            }.padding()
                        }
                    }
                }
                
                HStack {
                    SectionHeader(title: "All Games")
                    Spacer()
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
                }.padding([.horizontal, .top])
                
                if games.count == 0 {
                    MessageBlock {
                        Text("No Games")
                            .fontWeight(.medium)
                            .padding([.top, .horizontal], 8.0)
                        Text("You haven't added any games to your library. Use the \(Image(systemName: "plus")) button to add games.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding([.bottom, .horizontal], 8.0)
                    }
                } else {
                    LazyVGrid(columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)], spacing: 16.0) {
                        ForEach(games) { item in
                            GameGridItem(game: item, selectedGame: $selectedGame)
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchQuery)
            .fileImporter(isPresented: $isRomPickerOpen, allowedContentTypes: Self.romFileTypes, onCompletion: self.fileImported)
            .alert(isPresented: $isUnknownSystemDialogShown, content: {
                Alert(
                    title: Text("Failed to add game"),
                    message: Text("The game you tried to upload has an invalid file type and is not supported by Eclipse.")
                )
            })
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
                            Label("Files", systemImage: "folder")
                        }
                        NavigationLink(destination: HomebrewView()) {
                            Label("Homebrew", systemImage: "mug")
                        }
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onChange(of: searchQuery) { newValue in
                games.nsPredicate = newValue.isEmpty ? nil : NSPredicate(format: "name CONTAINS %@", newValue)
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
        }
    }
    
    func fileImported(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task.detached(priority: .userInitiated) {
                do {
                    guard url.startAccessingSecurityScopedResource() else {
                        print("access denied")
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }

                    var resource: URLResourceValues?
                    do {
                        resource = try url.resourceValues(forKeys: [.contentTypeKey])
                    } catch {
                        print(error)
                    }
                    let fileType = resource?.contentType
                    
                    let system = if let fileType {
                        GameSystem.from(fileType: fileType)
                    } else {
                        GameSystem.unknown
                    }
                    
                    guard system != .unknown else {
                        await MainActor.run {
                            self.isUnknownSystemDialogShown = true
                        }
                        return
                    }

                    let fileName = url.lastPathComponent
                    
                    var name = fileName
                    var romExtension: String?
                    
                    let fileExtensionIndex = fileName.firstIndex(of: ".")
                    if let fileExtensionIndex {
                        name = String(fileName.prefix(upTo: fileExtensionIndex))
                        romExtension = String(fileName[fileExtensionIndex...])
                    }

                    try await persistence.games.insert(name: name, system: system, romPath: url, romExtension: romExtension)
                } catch {
                    print(error)
                }
            }
            break
        case .failure(let err):
            print(err)
            break
        }
    }
}

#if DEBUG
#Preview {
    LibraryView()
        .environment(\.managedObjectContext, PersistenceCoordinator.preview.container.viewContext)
}
#endif
