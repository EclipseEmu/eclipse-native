import SwiftUI
import CoreData
import OSLog
import EclipseKit

// FIXME: Navigating away from the view will cause the filters to be ignored.

struct LibraryView: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var navigation: NavigationManager

    @FetchRequest<Game>(
        sortDescriptors: Self.getSortDescriptors(for: Settings.getSortDirection(), method: Settings.getSortMethod()),
        animation: .default
    )
    private var games: FetchedResults<Game>

    @State private var query: String = ""

    @State private var isSelecting = false
    @State private var selection: Set<Game> = []
    @State private var renameTarget: Game?
    @State private var deleteTarget: Game?
    @State private var fileImportType: FileImportType?
    @State private var manageTagsTarget: ManageTagsTarget?
    @State private var coverPickerMethod: CoverPickerMethod?

    @StateObject private var filtersModel = LibraryFiltersViewModel()

    @ViewBuilder
    var content: some View {
        let showExtraContent = !isSelecting && query.isEmpty

        if !games.isEmpty {
            ScrollView {
                if showExtraContent {
                    KeepPlayingSection()
                }

                Section {
                    gameList
                } header: {
                    if showExtraContent {
                        Text("All Games")
                            .sectionHeaderStyle()
                            .padding([.horizontal, .top])
                    }
                }
            }
            .headerProminence(.increased)
        } else if games.isEmpty && !query.isEmpty {
            ContentUnavailableMessage {
                Label("No Results", systemImage: "magnifyingglass")
            } description: {
                Text("No results for \"\(query)\"")
            }
        } else if games.isEmpty && (filtersModel.areSystemsFiltered || !filtersModel.tags.isEmpty) {
            ContentUnavailableMessage {
                Label("No Results", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("All games are filtered out.")
            }
        } else {
            ContentUnavailableMessage {
                Label("No Games", systemImage: "books.vertical")
            } description: {
                Text("You don't have any games in your library.")
            }
        }
    }

    var body: some View {
        content
            .navigationTitle("Library")
            .multiFileImporter($fileImportType)
            .toolbar {
                toolbarContent
            }
            .searchable(text: $query, prompt: "Search Games")
            .onChange(of: settings.listSortMethod, perform: updateSortDescriptor)
            .onChange(of: settings.listSortDirection, perform: updateSortDescriptor)
            .onSubmit(of: .search) {
                games.nsPredicate = self.predicate(for: query)
            }
            .onChange(of: query) { newQuery in
                games.nsPredicate = self.predicate(for: newQuery)
            }
            .onChange(of: filtersModel.tags) { _ in
                games.nsPredicate = self.predicate(for: query)
            }
            .onChange(of: filtersModel.systems) { _ in
                games.nsPredicate = self.predicate(for: query)
            }
            .onAppear {
                games.nsSortDescriptors = getSortDescriptors()
                games.nsPredicate = self.predicate(for: query)
            }
            .coverPicker(presenting: $coverPickerMethod)
            .renameItem("Rename Game", item: $renameTarget)
            .deleteItem("Remove Game", item: $deleteTarget) { game in
                Text("Are you sure you want to remove \"\(game.name ?? "this game")\"? Your save, save states, and cheats will be deleted as well.")
            }
            .sheet(isPresented: $filtersModel.isPresented) {
                NavigationStack {
                    LibraryFiltersView(viewModel: filtersModel)
                }.presentationDetents([.medium, .large])
            }
            .sheet(item: $manageTagsTarget) {
                try? persistence.mainContext.saveIfNeeded()
            } content: { target in
                NavigationStack {
                    ManageTagsView(target: target)
                }
            }
    }

    // MARK: Game List

    @ViewBuilder
    var gameList: some View {
        let spacing = 16.0

        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 120, maximum: 240), spacing: spacing, alignment: .top)],
            spacing: spacing
        ) {
            ForEach(games) { game in
                let _ = Self._printChanges()
                if !game.isDeleted && !game.isFault {
                    let isSelected = self.selection.contains(game)
                    Button {
                        gameSelected(game)
                    } label: {
                        DualLabeledImage(title: Text(game.name ?? "Game"), subtitle: Text(game.system.string)) {
                            LocalImage(game.cover) { image in
                                image
                                    .resizable()
                                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8.0)
                                    .foregroundStyle(.secondary)
                            }
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay(alignment: .bottomTrailing) {
                                GameItemCheckbox(isSelected: isSelected)
                                    .opacity(Double(isSelecting))
                                    .padding(8.0)
                            }
                        }
                        .contentShape(Rectangle())
                        .opacity(isSelecting && !isSelected ? 0.5 : 1.0)
                    }
                    .contextMenu {
                        Button {
                            self.manageTagsTarget = .one(game)
                        } label: {
                            Label("Manage Tags", systemImage: "tag")
                        }

                        Button {
                            navigation.path.append(Destination.cheats(game))
                        } label: {
                            Label("Manage Cheats", systemImage: "memorychip")
                        }

                        Divider()

                        Button {
                            self.renameTarget = game
                        } label: {
                            Label("Rename...", systemImage: "text.cursor")
                        }

                        CoverPickerMenu(game: game, coverPickerMethod: $coverPickerMethod)

                        Divider()

                        Button(role: .destructive) {
                            self.deleteTarget = game
                        } label: {
                            Label("Remove...", systemImage: "trash")
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding([.horizontal, .bottom])
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if !os(macOS)
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink(to: .settings) {
                Label("Settings", systemImage: "gear")
            }
        }
        #endif

        ToolbarItem {
            Menu {
                if !self.isSelecting {
                    Button {
                        withAnimation {
                            self.isSelecting = true
                        }
                    } label: {
                        Label("Select", systemImage: "checkmark.circle")
                    }
                }

                Button {
                    filtersModel.isPresented = true
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease")
                }

                Picker(selection: $settings.listSortMethod) {
                    Text("Name").tag(GameListSortingMethod.name)
                    Text("Date Added").tag(GameListSortingMethod.dateAdded)
                } label: {
                    Label("Sort By", systemImage: "arrow.up.arrow.down")
                }

                Picker(selection: $settings.listSortDirection) {
                    Text("Ascending").tag(GameListSortingDirection.ascending)
                    Text("Descending").tag(GameListSortingDirection.descending)
                } label: {
                    Label("Order By", systemImage: "arrow.up.arrow.down")
                }
            } label: {
                Label("Options", systemImage: "ellipsis.circle")
            }
        }

        if !isSelecting {
            ToolbarItem {
                Button(action: self.addGames) {
                    Label("Add Games", systemImage: "plus")
                }
            }
        }

        #if os(iOS)
        if isSelecting {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(role: .destructive) {
                    Task {
                        let boxes = selection.map(ObjectBox.init)
                        Task {
                            try await persistence.objects.deleteMany(boxes)
                        }
                    }
                } label: {
                    Label("Remove...", systemImage: "trash")
                }
                .disabled(selection.isEmpty)

                Spacer()

                Button {
                    if selection.count == 1 {
                        self.manageTagsTarget = .one(selection.first!)
                    } else {
                        self.manageTagsTarget = .many(selection)
                    }
                } label: {
                    Label("Manage Tags", systemImage: "tag")
                }
                .disabled(selection.isEmpty)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Done", role: .cancel) {
                    withAnimation {
                        self.isSelecting = false
                        self.selection.removeAll()
                    }
                }
            }
        }
        #endif
    }

    // MARK: Functions

    private func addGames() {
        self.fileImportType = .roms(multiple: true, completion: handleUploadedRoms)
    }

    @Sendable
    private nonisolated func handleUploadedRoms(result: Result<[URL], any Error>) {
        Task {
            do {
                let roms = try result.get()
                let failedGames = try await persistence.objects.createGames(for: roms)
                // FIXME: Present failed games
                print(failedGames)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }

    private func gameSelected(_ game: Game) {
        if !isSelecting {
            navigation.path.append(Destination.game(game))
        } else if selection.contains(game) {
            withAnimation {
                _ = selection.remove(game)
            }
        } else {
            withAnimation {
                _ = selection.insert(game)
            }
        }
    }

    private func updateSortDescriptor<T>(_: T) {
        games.nsSortDescriptors = self.getSortDescriptors()
    }

    private func predicate(for query: String) -> NSPredicate? {
        var predicates: [NSPredicate] = []

        if !query.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[d] %@", query))
        }

        filtersModel.insertPredicates(&predicates)

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func getSortDescriptors() -> [NSSortDescriptor] {
        Self.getSortDescriptors(for: settings.listSortDirection, method: settings.listSortMethod)
    }

    private static func getSortDescriptors(for direction: GameListSortingDirection, method: GameListSortingMethod) -> [NSSortDescriptor] {
        let isAscending = direction == .ascending
        return switch method {
        case .name: [NSSortDescriptor(keyPath: \Game.name, ascending: isAscending)]
        case .dateAdded: [NSSortDescriptor(keyPath: \Game.dateAdded, ascending: isAscending)]
        }
    }
}

// MARK: Preview

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    @Previewable @StateObject var navigationManager = NavigationManager()

    NavigationStack(path: $navigationManager.path) {
        LibraryView()
    }
    .environmentObject(navigationManager)
    .environmentObject(Settings())
}
