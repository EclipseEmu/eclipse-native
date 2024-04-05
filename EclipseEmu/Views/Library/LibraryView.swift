import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct LibraryView: View {
    static let fileTypes: [UTType] = [.data]
    
    @Environment(\.managedObjectContext) private var viewContext
    @State var searchQuery: String = ""
    @State var isRomPickerOpen: Bool = false
    @State var selectedGame: Game? = nil
    @State var isSettingsOpen = false
    
    @Environment(\.playGame) private var playGame
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Game.dateAdded, ascending: true)],
        animation: .default)
    private var recentlyPlayed: FetchedResults<Game>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Game.name, ascending: true)],
        animation: .default)
    private var games: FetchedResults<Game>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0.0) {
                    SectionHeader(title: "Keep Playing")
                        .padding([.horizontal, .top])
                    
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 16.0) {
                            ForEach(recentlyPlayed) { item in
                                GameKeepPlayingItem(game: item, selectedGame: $selectedGame)
                            }
                        }.padding()
                    }
                }
                
                HStack {
                    SectionHeader(title: "All Games")
                    Spacer()
                    Button {} label: {
                        Label("Sort & Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }.labelStyle(.iconOnly)
                }.padding([.horizontal, .top])
                LazyVGrid(columns: [.init(.adaptive(minimum: 140.0, maximum: 240.0))]) {
                    ForEach(games) { item in
                        GameGridItem(game: item, selectedGame: $selectedGame)
                    }
                    .onDelete(perform: deleteItems)
                }.padding([.horizontal, .bottom])
            }
            .navigationTitle("Library")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.isSettingsOpen = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                #else
                ToolbarItem(placement: .navigation) {
                    Button {
                        self.isSettingsOpen = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem {
                    Button {
                        Task {
                            try? await playGame(game: Game())
                        }
                    } label: {
                        Label("Emulation View", systemImage: "play.fill")
                    }
                }
#endif
                ToolbarItem {
                    Button {
                        self.isRomPickerOpen = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchQuery)
            .onChange(of: searchQuery) { newValue in
                games.nsPredicate = newValue.isEmpty ? nil : NSPredicate(format: "name CONTAINS %@", newValue)
            }
            .fileImporter(isPresented: $isRomPickerOpen, allowedContentTypes: Self.fileTypes, onCompletion: { result in
                switch result {
                case .success(let url):
                    let fileName = url.lastPathComponent
                    guard let fileExtensionIndex = fileName.firstIndex(of: ".") else {
                        return
                    }
                    
                    let fileExtension = fileName[fileExtensionIndex...]
                    let system: GameSystem = switch fileExtension {
                    case ".gb": .gb
                    case ".gbc": .gbc
                    default: .unknown
                    }
                    
                    guard system != .unknown else {
                        print("invalid system")
                        return
                    }
                    
                    Task {
                        do {
                            guard url.startAccessingSecurityScopedResource() else {
                                print("access denied")
                                return
                            }
                            defer { url.stopAccessingSecurityScopedResource() }
                            let bytes = try Data(contentsOf: url)
                            let md5Digest = try await MD5Hasher().hash(data: bytes)
                            let md5 = MD5Hasher.stringFromDigest(digest: md5Digest)
                            
                            await MainActor.run {
                                withAnimation {
                                    let newGame = Game(context: self.viewContext)
                                    newGame.name = String(fileName.prefix(upTo: fileExtensionIndex))
                                    newGame.system = system
                                    newGame.dateAdded = Date.now
                                    newGame.md5 = md5
                                    
                                    do {
                                        try viewContext.save()
                                    } catch {
                                        // Replace this implementation with code to handle the error appropriately.
                                        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                        let nsError = error as NSError
                                        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                    }
                                }
                            }
                        } catch {
                            print(error)
                        }
                    }
                    break
                case .failure(let err):
                    print(err)
                    break
                }
            })
            .sheet(item: $selectedGame) { game in
                NavigationStack {
                    GameView(game: game)
                }
            }
            .sheet(isPresented: $isSettingsOpen) {
                SettingsView()
                #if os(macOS)
                    .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
                #endif
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for offset in offsets {
                let game = games[offset]
                viewContext.delete(game)
            }

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    LibraryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
