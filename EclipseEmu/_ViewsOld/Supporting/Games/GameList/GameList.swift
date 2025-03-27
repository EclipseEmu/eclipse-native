import CoreData
import SwiftUI

// MARK: - View Model

@MainActor
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
        case tag(Tag)
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
        switch filter {
        case .none:
            return isEmpty
                ? nil
                : NSPredicate(format: "name CONTAINS %@", query)
        case .tag(let collection):
            return isEmpty
                ? NSPredicate(format: "%K CONTAINS %@", #keyPath(Game.tags), collection)
                : NSPredicate(
                    format: "(%K CONTAINS %@) AND (name CONTAINS %@)",
                    #keyPath(Game.tags),
                    collection,
                    query
                )
        }
    }

    func removeFromLibrary(in persistence: Persistence) {
        Task {
            do {
                try await persistence.objects.deleteMany(selection.boxedItems())
            } catch {
                // FIXME: Handle error
                print(error)
            }
        }
    }

    // FIXME: Rewrite
    func removeFromCollection(in persistence: Persistence) {
        guard case .tag(let collection) = filter else {
            return
        }
        for game in selection {
            collection.removeFromGames(game)
        }
        do {
            try persistence.mainContext.saveIfNeeded()
        } catch {
            // FIXME: Handle error
            print(error)
        }
    }

    // FIXME: Rewrite
    func addSelectionToCollection(collection: Tag, in persistence: Persistence) {
        for game in selection {
            collection.addToGames(game)
        }

        do {
            try persistence.mainContext.saveIfNeeded()
        } catch {
            print(error)
        }
    }
}

// MARK: - View

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct GameList: View {
    @ObservedObject var viewModel: GameListViewModel
    @EnvironmentObject var persistence: Persistence
    @FetchRequest<Game>(sortDescriptors: [], animation: .default)
    var games: FetchedResults<Game>

    init(viewModel: GameListViewModel) {
        self.viewModel = viewModel
        let fetchRequest = Game.fetchRequest()
        fetchRequest.sortDescriptors = viewModel.sortMethod.sortDescriptors(direction: viewModel.sortDirection)
        self._games = FetchRequest(fetchRequest: fetchRequest)
    }

    var body: some View {
        LazyVGrid(
            columns: [
                .init(
                    .adaptive(minimum: 160.0, maximum: 240.0),
                    spacing: 16.0,
                    alignment: .top
                )
            ],
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
        .renameItemAlert(
            $viewModel.renameTarget,
            key: \Game.name,
            title: "Rename Game",
            placeholder: "Game Name"
        ) { game, name in
            game.name = name
            // FIXME: Handle
            try? persistence.mainContext.saveIfNeeded()
        }
        .sheet(item: $viewModel.changeBoxartTarget) { game in
            BoxartDatabasePicker(system: game.system, initialQuery: game.name ?? "") { entry in
                self.photoFromDatabase(entry: entry, game: game)
            }
        }
        .sheet(isPresented: $viewModel.isAddToCollectionOpen) {
            AddToTagView(viewModel: viewModel)
        }
        .confirmationDialog("", isPresented: $viewModel.isDeleteConfirmationOpen) {
            if case .tag = viewModel.filter {
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

    func photoFromDatabase(entry: OpenVGDBItem, game: Game) {
        guard let url = entry.cover else { return }
        Task {
            do {
                try await persistence.objects.replaceCoverArt(game: .init(game), fromRemote: url)
            } catch {
                // FIXME: present this to the user
                print(error)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    @Previewable @StateObject var viewModel = GameListViewModel(filter: .none)

    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
         NavigationStack {
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
