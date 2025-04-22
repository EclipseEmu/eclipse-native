import SwiftUI
import CoreData
import OSLog
import EclipseKit

struct LibraryView: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var navigation: NavigationManager

    @FetchRequest<GameObject>(
        sortDescriptors: Self.getSortDescriptors(
            for: Settings.getSortDirection(),
            method: Settings.getSortMethod()
        ),
        animation: .default
    )
    private var games: FetchedResults<GameObject>

    @State private var query: String = ""

    @State private var isSelecting = false
    @State private var selection: Set<GameObject> = []
    @State private var renameTarget: GameObject?
    @State private var deleteTarget: GameObject?
    @State private var fileImportType: FileImportType?
    @State private var manageTagsTarget: ManageTagsTarget?
    @State private var coverPickerMethod: CoverPickerMethod?

    @State var isFiltersViewPresented: Bool = false
    @State var filteredSystems: Set<GameSystem> = Set(GameSystem.concreteCases)
    @State var filteredTags: Set<TagObject> = []

    var areSystemsFiltered: Bool { filteredSystems.count != GameSystem.concreteCases.count }

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
                        Text("ALL_GAMES")
                            .sectionHeaderStyle()
                            .padding([.horizontal, .top])
                    }
                }
            }
            .headerProminence(.increased)
        } else if games.isEmpty && !query.isEmpty {
            ContentUnavailableMessage.search(text: query)
        } else if games.isEmpty && (areSystemsFiltered || !filteredTags.isEmpty) {
            ContentUnavailableMessage {
                Label("NO_RESULTS_FILTERED_TITLE", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("NO_RESULTS_FILTERED_MESSAGE")
            }
        } else {
            ContentUnavailableMessage {
                Label("EMPTY_LIBRARY_TITLE", systemImage: "books.vertical")
            } description: {
                Text("EMPTY_LIBRARY_MESSAGE")
            }
        }
    }

    var body: some View {
        content
            .navigationTitle("LIBRARY")
            .multiFileImporter($fileImportType)
            .toolbar {
                toolbarContent
            }
            .searchable(text: $query, prompt: "SEARCH_GAMES")
            .onChange(of: settings.listSortMethod, perform: updateSortDescriptor)
            .onChange(of: settings.listSortDirection, perform: updateSortDescriptor)
            .onSubmit(of: .search) {
                games.nsPredicate = self.predicate(for: query)
            }
            .onChange(of: query) { newQuery in
                games.nsPredicate = self.predicate(for: newQuery)
            }
            .onChange(of: filteredTags) { _ in
                games.nsPredicate = self.predicate(for: query)
            }
            .onChange(of: filteredSystems) { _ in
                games.nsPredicate = self.predicate(for: query)
            }
            .onAppear {
                games.nsSortDescriptors = getSortDescriptors()
                games.nsPredicate = self.predicate(for: query)
            }
            .coverPicker(presenting: $coverPickerMethod)
            .renameItem("RENAME_GAME", item: $renameTarget)
            .deleteItem("DELETE_GAME", item: $deleteTarget) { game in
                Text("DELETE_GAME_MESSAGE \(game.name ?? String(localized: "GAME_UNNAMED"))")
            }
            .sheet(isPresented: $isFiltersViewPresented) {
                NavigationStack {
                    LibraryFiltersView(systems: $filteredSystems, tags: $filteredTags)
                }.presentationDetents([.medium, .large])
            }
            .sheet(item: $manageTagsTarget) { target in
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
                if !game.isDeleted && !game.isFault {
                    let isSelected = self.selection.contains(game)
                    Button {
                        gameSelected(game)
                    } label: {
                        DualLabeledImage(
                            title: Text(verbatim: game.name, fallback: "GAME_UNNAMED"),
                            subtitle: Text(game.system.string)
                        ) {
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
                            Label("MANAGE_TAGS", systemImage: "tag")
                        }

                        NavigationLink(to: .cheats(game)) {
                            Label("MANAGE_CHEATS", systemImage: "memorychip")
                        }

                        Divider()

                        Button {
                            self.renameTarget = game
                        } label: {
                            Label("RENAME", systemImage: "text.cursor")
                        }

                        CoverPickerMenu(game: game, coverPickerMethod: $coverPickerMethod)

                        Divider()

                        Button(role: .destructive) {
                            self.deleteTarget = game
                        } label: {
                            Label("DELETE", systemImage: "trash")
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
                Label("SETTINGS", systemImage: "gear")
            }
        }
        #endif

        ToolbarItem {
            Menu {
                if !self.isSelecting {
                    ToggleButton(value: $isSelecting) {
                        Label("SELECT", systemImage: "checkmark.circle")
                    }
                }


                ToggleButton(value: $isFiltersViewPresented) {
                    Label("FILTER", systemImage: "line.3.horizontal.decrease")
                }

                Picker(selection: $settings.listSortMethod) {
                    Text("NAME").tag(GameListSortingMethod.name)
                    Text("DATE_ADDED").tag(GameListSortingMethod.dateAdded)
                } label: {
                    Label("SORT_BY", systemImage: "arrow.up.arrow.down")
                }

                Picker(selection: $settings.listSortDirection) {
                    Text("ASCENDING").tag(GameListSortingDirection.ascending)
                    Text("DESCENDING").tag(GameListSortingDirection.descending)
                } label: {
                    Label("ORDER_BY", systemImage: "arrow.up.arrow.down")
                }
            } label: {
                Label("OPTIONS", systemImage: "ellipsis.circle")
            }
        }

        if !isSelecting {
            ToolbarItem {
                Button(action: self.addGames) {
                    Label("ADD GAMES", systemImage: "plus")
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
                    Label("DELETE", systemImage: "trash")
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
                    Label("MANAGE_TAGS", systemImage: "tag")
                }
                .disabled(selection.isEmpty)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("DONE", role: .cancel) {
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

    private func gameSelected(_ game: GameObject) {
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

        predicates.append(
            NSCompoundPredicate(orPredicateWithSubpredicates: filteredSystems.map {
                NSPredicate(format: "rawSystem = %d", $0.rawValue)
            })
        )

        for tag in filteredTags {
            predicates.append(NSPredicate(format: "tags CONTAINS %@", tag))
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func getSortDescriptors() -> [NSSortDescriptor] {
        Self.getSortDescriptors(for: settings.listSortDirection, method: settings.listSortMethod)
    }

    private static func getSortDescriptors(for direction: GameListSortingDirection, method: GameListSortingMethod) -> [NSSortDescriptor] {
        let isAscending = direction == .ascending
        return switch method {
        case .name: [NSSortDescriptor(keyPath: \GameObject.name, ascending: isAscending)]
        case .dateAdded: [NSSortDescriptor(keyPath: \GameObject.dateAdded, ascending: isAscending)]
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
