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
    @State var isCreateCollectionOpen = false
    @State var isUnknownSystemDialogShown = false
    @State var isTargeted = false
    
    @FetchRequest(
        fetchRequest: Self.recentlyPlayedRequest,
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
    
    var collectionsSection: some View {
        Section {
            LazyVGrid(columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)], spacing: 16.0) {
                ForEach(collections) { collection in
                    NavigationLink {
                        GameCollectionView(collection: collection)
                    } label: {
                        VStack(alignment: .leading) {
                            CollectionIconView(icon: collection.icon)
                                .aspectRatio(1.0, contentMode: .fit)
                                .fixedSize()
                                .frame(width: 32, height: 32)
                                .padding(.bottom, 8.0)
                            
                            Text(collection.name ?? "Unnamed Collection")
                                .fontWeight(.medium)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .backgroundGradient(color: collection.parsedColor.color)
                        .clipShape(RoundedRectangle(cornerRadius: 16.0))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            CollectionManager.delete(collection, in: persistence)
                        } label: {
                            Label("Delete Collection", systemImage: "trash")
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
        } header: {
            SectionHeader("Collections").padding([.horizontal, .top])
        }
        .emptyState(collections.isEmpty) {
            EmptyView()
        }
    }
    
    var body: some View {
        CompatNavigationStack {
            ScrollView {
                if !games.isEmpty {
                    Section {
                        ScrollView(.horizontal) {
                            LazyHStack(alignment: .top, spacing: 16.0) {
                                ForEach(recentlyPlayed) { item in
                                    GameKeepPlayingItem(game: item, selectedGame: $selectedGame)
                                }
                            }
                            .padding([.horizontal, .bottom])
                        }
                        .emptyMessage(self.recentlyPlayed.isEmpty) {
                            Text("No Played Games")
                        } message: {
                            Text("As you play games, they'll show up here so you can quickly jump back in.")
                        }
                    } header: {
                        SectionHeader("Keep Playing")
                            .padding([.horizontal, .top])
                    }
                }
                
                self.collectionsSection
                
                Section {
                    GameGrid(games: self.games, selectedGame: $selectedGame)
                        .padding([.horizontal, .bottom])
                        .emptyMessage(self.games.isEmpty) {
                            Text("No Games")
                        } message: {
                            Text("You haven't added any games to your library. Use the \(Image(systemName: "plus")) button in the navigation bar to add games.")
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
            .navigationTitle("Library")
            .searchable(text: $searchQuery)
            .fileImporter(isPresented: $isRomPickerOpen, allowedContentTypes: Self.romFileTypes, onCompletion: self.fileImported)
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
            .sheet(isPresented: $isCreateCollectionOpen) {
                NewCollectionView()
                #if os(macOS)
                    .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
                #endif
            }
            .alert(isPresented: $isUnknownSystemDialogShown, content: {
                Alert(
                    title: Text("Failed to add game"),
                    message: Text("The game you tried to upload has an invalid file type and is not supported by Eclipse.")
                )
            })
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

                    try await GameManager.insert(
                        name: name,
                        system: system,
                        romPath: url,
                        romExtension: romExtension,
                        in: persistence
                    )
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
