import CoreData
import EclipseKit
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    static let recentlyPlayedRequest: NSFetchRequest<Game> = {
        let request = Game.fetchRequest()
        request.fetchLimit = 10
        request.predicate = NSPredicate(format: "datePlayed != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Game.datePlayed, ascending: false)]
        return request
    }()

    enum Failure: LocalizedError {
        case persistence(PersistenceError)
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
    @Environment(\.persistence) private var persistence
    @Environment(\.playGame) private var playGame
    @StateObject var viewModel: GameListViewModel = .init(filter: .none)

    @State var isRomPickerOpen: Bool = false
    @State var isErrorDialogOpen = false
    @State var error: Self.Failure?

    @FetchRequest(fetchRequest: Self.recentlyPlayedRequest, animation: .default)
    private var recentlyPlayed: FetchedResults<Game>

    var body: some View {
        CompatNavigationStack {
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
                allowsMultipleSelection: true,
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

    func fileImported(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task.detached(priority: .userInitiated) {
                do {
                    let openvgdb = try? await OpenVGDB()
                    let results = try await persistence.create(games: urls, openvgdb: openvgdb)
                    let errors = results.compactMap {
                        switch $0 {
                        case .failure(originalPath: let path, error: let error): (path, error)
                        case .success(_): nil
                        }
                    }
                    if !errors.isEmpty {
                        print(errors)
                    }
                } catch {
                    print(error)
                }
            }
        case .failure(let err):
            print(err)
        }
    }

    func onPlayFailure(error: PlayGameAction.Failure, game: Persistence.Object<Game>) {
        self.reportError(error: .playAction(error))
    }

    func reportError(error: Self.Failure) {
        self.error = error
        self.isErrorDialogOpen = true
    }
}

#if DEBUG
#Preview {
    let persistence = Persistence.preview
    let viewContext = persistence.viewContext

    for index in 0 ..< 5 {
        let game = Game(context: viewContext)
        game.name = "Game \(index)"
        game.system = .gba
        game.id = UUID()
        game.md5 = ""
        game.datePlayed = Date.now
        game.dateAdded = Date.now
    }

    return LibraryView()
        .environment(\.managedObjectContext, viewContext)
        .environment(\.persistence, persistence)
}
#endif
