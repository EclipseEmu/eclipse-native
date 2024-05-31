import SwiftUI
import CoreData

// MARK: - View Model

final class GameListViewModel: ObservableObject {
    enum DisplayMode: Identifiable, CaseIterable, Equatable {
        case grid
        case list

        var id: Int {
            switch self {
            case .grid: 0
            case .list: 1
            }
        }

        var label: some View {
            switch self {
            case .grid: Label("Grid", systemImage: "square.grid.2x2")
            case .list: Label("List", systemImage: "list.bullet")
            }
        }
    }

    enum SortMethod: Identifiable, CaseIterable, Equatable {
        case name
        case dateAdded

        var id: Int {
            switch self {
            case .name: 0
            case .dateAdded: 1
            }
        }

        var displayName: LocalizedStringKey {
            switch self {
            case .name: "Name"
            case .dateAdded: "Date Added"
            }
        }

        func sortDescriptors(direction: SortDirection) -> [NSSortDescriptor] {
            let isAscending = direction == .ascending
            return switch self {
            case .name: [NSSortDescriptor(keyPath: \Game.name, ascending: isAscending)]
            case .dateAdded: [NSSortDescriptor(keyPath: \Game.dateAdded, ascending: isAscending)]
            }
        }
    }

    enum SortDirection: Identifiable, CaseIterable, Equatable {
        case ascending
        case descending

        var id: Int {
            switch self {
            case .ascending: 0
            case .descending: 1
            }
        }

        var displayName: LocalizedStringKey {
            switch self {
            case .ascending: "Ascending"
            case .descending: "Descending"
            }
        }
    }

    enum Filter {
        case none
        case collection(GameCollection)
    }

    let filter: Filter
    @Published var isEmpty: Bool = false

    @Published var isSelecting: Bool = false
    @Published var selection = Set<Game>()

    @Published var displayMode: DisplayMode = .grid
    @Published var sortMethod: SortMethod = .name
    @Published var sortDirection: SortDirection = .ascending

    @Published var searchQuery: String = ""
    @Published var isDeleteConfirmationOpen: Bool = false
    @Published var isAddToCollectionOpen: Bool = false

    @Published var target: Game?
    @Published var changeBoxartTarget: Game?
    @Published var renameTarget: Game?

    init(filter: Filter) {
        self.filter = filter
    }

    func nsPredicate(for query: String) -> NSPredicate? {
        let isEmpty = query.isEmpty
        switch self.filter {
        case .none:
            return isEmpty
                ? nil
                : NSPredicate(format: "name CONTAINS %@", query)
        case .collection(let collection):
            return isEmpty
                ? NSPredicate(format: "%K CONTAINS %@", #keyPath(Game.collections), collection)
                : NSPredicate(
                    format: "(%K CONTAINS %@) AND (name CONTAINS %@)",
                    #keyPath(Game.collections),
                    collection,
                    query)
        }
    }

    func removeFromLibrary(in persistence: PersistenceCoordinator) {
        for game in selection {
            persistence.context.delete(game)
        }
        persistence.saveIfNeeded()
    }

    func removeFromCollection(in persistence: PersistenceCoordinator) {
        guard case .collection(let collection) = filter else {
            return
        }
        for game in selection {
            collection.removeFromGames(game)
        }
        persistence.saveIfNeeded()
    }

    func addSelectionToCollection(collection: GameCollection, in persistence: PersistenceCoordinator) {
        for game in selection {
            collection.addToGames(game)
        }
        persistence.saveIfNeeded()
    }
}

// MARK: - View

struct GameList: View {
    @ObservedObject var viewModel: GameListViewModel
    @Environment(\.persistenceCoordinator) var persistence
    @FetchRequest<Game>(sortDescriptors: [], animation: .default) var games: FetchedResults<Game>

    init(viewModel: GameListViewModel) {
        self.viewModel = viewModel
        let fetchRequest = Game.fetchRequest()
        fetchRequest.sortDescriptors = viewModel.sortMethod.sortDescriptors(direction: viewModel.sortDirection)
        self._games = FetchRequest(fetchRequest: fetchRequest)
    }

    var body: some View {
        Group {
            switch viewModel.displayMode {
            case .grid:
                LazyVGrid(
                    columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)],
                    spacing: 16.0
                ) {
                    ForEach(games) { game in
                        Button {
                            self.gameAction(game: game)
                        } label: {
                            GameListGridItem(viewModel: viewModel, game: game)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            GameListItemContextMenu(viewModel: viewModel, game: game)
                        }
                    }
                }
                .padding()
            case .list:
                LazyVStack(alignment: .leading, spacing: 0.0) {
                    ForEach(games) { game in
                        Button {
                            self.gameAction(game: game)
                        } label: {
                            GameListListItem(viewModel: viewModel, game: game)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .padding(.horizontal)
                                        .foregroundStyle(.tertiary)
                                        .opacity(0.6)
                                        .frame(height: 1)
                                        .opacity(Double(game != games.last))
                                }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            GameListItemContextMenu(viewModel: viewModel, game: game)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.isEmpty = games.isEmpty
        }
        .onDisappear {
            viewModel.selection.removeAll()
        }
        .onChange(of: games.isEmpty) { isEmpty in
            viewModel.isEmpty = isEmpty
        }
        .onReceive(viewModel.$searchQuery.debounce(for: 1, scheduler: RunLoop.main)) { query in
            games.nsPredicate = viewModel.nsPredicate(for: query)
        }
        .onChange(of: viewModel.sortMethod) { _ in
            self.sortChanged()
        }
        .onChange(of: viewModel.sortDirection) { _ in
            self.sortChanged()
        }
        .renameAlert(
            $viewModel.renameTarget,
            key: \Game.name,
            title: "Rename Game",
            placeholder: "Game Name"
        ) { game, name in
            game.name = name
            persistence.saveIfNeeded()
        }
        .sheet(item: $viewModel.changeBoxartTarget) { game in
            BoxartPicker(system: game.system, initialQuery: game.name ?? "") { entry in
                self.photoFromDatabase(entry: entry, game: game)
            }
        }
        .sheet(isPresented: $viewModel.isAddToCollectionOpen) {
            AddToCollectionView(viewModel: viewModel)
        }
        .confirmationDialog("", isPresented: $viewModel.isDeleteConfirmationOpen) {
            if case .collection = viewModel.filter {
                Button("Remove from Collection") {
                    viewModel.removeFromCollection(in: persistence)
                }
            }
            Button("Remove from Library", role: .destructive) {
                viewModel.removeFromLibrary(in: persistence)
            }
        } message: {
            Text("Are you sure you want to remove \(viewModel.selection.count == 1 ? "this game" : "these games")?")
        }
    }

    func gameAction(game: Game) {
        if viewModel.isSelecting {
            if viewModel.selection.contains(game) {
                viewModel.selection.remove(game)
            } else {
                viewModel.selection.insert(game)
            }
        } else {
            viewModel.target = game
        }
    }

    func sortChanged() {
        games.nsSortDescriptors = viewModel.sortMethod.sortDescriptors(direction: viewModel.sortDirection)
    }

    func photoFromDatabase(entry: OpenVGDB.Item, game: Game) {
        guard let url = entry.boxart else { return }
        Task {
            do {
                game.boxart = try await ImageAssetManager.create(remote: url, in: persistence, save: false)
                persistence.saveIfNeeded()
            } catch {
                // FIXME: present this to the user
                print(error)
            }
        }
    }
}

#Preview {
    struct MiniLibrary: View {
        @StateObject var viewModel = GameListViewModel(filter: .none)

        var body: some View {
            CompatNavigationStack {
                ScrollView {
                    GameList(viewModel: viewModel)
                }
                .emptyState(viewModel.isEmpty) {
                    EmptyGameListMessage(filter: viewModel.filter)
                }
                .navigationTitle("Library")
                .toolbar {
                    ToolbarItem {
                        if !viewModel.isSelecting {
                            Menu {
                                GameListMenuItems(viewModel: viewModel)
                            } label: {
                                Label("Game Options", systemImage: "ellipsis.circle")
                            }
                        }
                    }

                    #if !os(macOS)
                    GameListToolbarItems(viewModel: viewModel)
                    #endif
                }
                .searchable(text: $viewModel.searchQuery)
            }
        }
    }

    let persistence = PersistenceCoordinator.preview
    let viewContext = persistence.context

    for index in 0..<5 {
        let game = Game(context: viewContext)
        game.name = "Game \(index)"
        game.system = .gba
        game.id = UUID()
        game.md5 = ""
        game.datePlayed = Date.now
        game.dateAdded = Date.now
    }

    return MiniLibrary()
        .environment(\.persistenceCoordinator, persistence)
        .environment(\.managedObjectContext, viewContext)
}
