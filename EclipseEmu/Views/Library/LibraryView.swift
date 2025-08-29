import SwiftUI
import EclipseKit
import CoreData

struct LibraryView: View {
    @EnvironmentObject private var settings: Settings
    @EnvironmentObject private var persistence: Persistence
    
    @StateObject private var viewModel: LibraryViewModel = .init()
    @FetchRequest<SaveStateObject>(fetchRequest: Self.keepPlayingFetchRequest)
    private var keepPlaying: FetchedResults<SaveStateObject>
    @FetchRequest<GameObject>(sortDescriptors: LibraryViewModel.getSortDescriptors(), animation: .default)
    private var games: FetchedResults<GameObject>

    #if os(macOS)
    let minItemWidth: CGFloat = 160
    let maxItemWidth: CGFloat = 240
    #else
    let minItemWidth: CGFloat = 120
    let maxItemWidth: CGFloat = 240
    #endif
    let itemSpacing: CGFloat = 16

    var body: some View {
        content
            .navigationTitle("LIBRARY")
            .toolbar(content: toolbarContent)
            .searchable(text: $viewModel.query)
            .coverPicker(presenting: $viewModel.coverPickerMethod)
            .fileImporter($viewModel.fileImportRequest)
            .fileExporter(
                isPresented: .isSome($viewModel.fileExportRequest.document),
                document: viewModel.fileExportRequest.document,
                contentType: .save,
                defaultFilename: viewModel.fileExportRequest.document?.fileName,
                onCompletion: viewModel.handleFileExport
            )
            .onChange(of: settings.listSortMethod, perform: updateSortDescriptor)
            .onChange(of: settings.listSortDirection, perform: updateSortDescriptor)
            .onChange(of: viewModel.query, perform: updatePredicate)
            .onChange(of: viewModel.filteredTags, perform: updatePredicate)
            .onChange(of: viewModel.filteredSystems, perform: updatePredicate)
            .onSubmit(of: .search) {
                self.updatePredicate(())
            }
            .onAppear {
                self.updatePredicate(())
                self.updateSortDescriptor(())
            }
            .sheet(isPresented: $viewModel.isFiltersViewOpen) {
                FormSheetView {
                    LibraryFiltersView(viewModel: viewModel)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $viewModel.isTagsViewOpen) {
                FormSheetView {
                    TagsView()
                }
            }
            .sheet(item: $viewModel.gameCheatsTarget) { game in
                FormSheetView {
                    CheatsView(game: game)
                }
            }
            .sheet(item: $viewModel.gameSaveStatesTarget) { game in
                FormSheetView {
                    GameSaveStatesView(game: game)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $viewModel.gameSettingsTarget) { game in
                FormSheetView {
                    GameSettingsView(game: game)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $viewModel.manageTagsTarget) { target in
                FormSheetView {
                    TagsPickerView(target: target)
                }
            }
    }
    
    @ViewBuilder
    var content: some View {
        let showExtraContent = !viewModel.isSelecting && viewModel.query.isEmpty
        let hasNoGames = games.isEmpty
        
        if !hasNoGames {
            ScrollView {
                LazyVStack {
                    if showExtraContent && !keepPlaying.isEmpty {
                        Section {
                            keepPlayingList
                        } header: {
                            Text("KEEP_PLAYING")
                                .sectionHeaderStyle()
                                .padding([.horizontal, .top])
                        }
                    }
                    
                    Section {
                        gameList.padding([.horizontal, .bottom])
                    } header: {
                        if showExtraContent {
                            Text("ALL_GAMES")
                                .sectionHeaderStyle()
                                .padding([.horizontal, .top])
                        }
                    }
                }
            }
        } else if hasNoGames && !viewModel.query.isEmpty {
            ContentUnavailableMessage.search(text: viewModel.query)
        } else if hasNoGames && (viewModel.areSystemsFiltered || !viewModel.filteredTags.isEmpty) {
            ContentUnavailableMessage("NO_RESULTS_FILTERED_TITLE", systemImage: "line.3.horizontal.decrease.circle", description: "NO_RESULTS_FILTERED_MESSAGE")
        } else {
            ContentUnavailableMessage("EMPTY_LIBRARY_TITLE", systemImage: "books.vertical", description: "EMPTY_LIBRARY_MESSAGE")
        }
    }
    
    @ViewBuilder
    var gameList: some View {
        LazyVGrid(
            columns: [GridItem(
                .adaptive(minimum: minItemWidth, maximum: maxItemWidth),
                spacing: itemSpacing,
                alignment: .top
            )],
            spacing: itemSpacing
        ) {
            ForEach(games) { game in
                GameItemView(game: game, viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    var keepPlayingList: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16.0) {
                ForEach(keepPlaying) { saveState in
                    KeepPlayingItemView(saveState: saveState, viewModel: viewModel)
                }
            }
            .padding([.horizontal, .bottom])
            .modify {
                if #available(iOS 17.0, macOS 14.0, *) {
                    $0.scrollTargetLayout()
                } else {
                    $0
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .modify {
            if #available(iOS 17.0, macOS 14.0, *) {
                $0.scrollTargetBehavior(.viewAligned)
            } else {
                $0
            }
        }
    }
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem {
            Menu("OPTIONS", systemImage: "ellipsis") {
                if !viewModel.isSelecting {
                    ToggleButton("SELECT", systemImage: "checkmark.circle", value: $viewModel.isSelecting)
                }
                
                ToggleButton("FILTER", systemImage: "line.3.horizontal.decrease", value: $viewModel.isFiltersViewOpen)
                ToggleButton("TAGS", systemImage: "tag", value: $viewModel.isTagsViewOpen)
                
                Picker("SORT_BY", systemImage: "arrow.up.arrow.down", selection: $settings.listSortMethod) {
                    Text("NAME").tag(GameListSortingMethod.name)
                    Text("DATE_ADDED").tag(GameListSortingMethod.dateAdded)
                }
                
                Picker("ORDER_BY", systemImage: "arrow.up.arrow.down", selection: $settings.listSortDirection) {
                    Text("ASCENDING").tag(GameListSortingDirection.ascending)
                    Text("DESCENDING").tag(GameListSortingDirection.descending)
                }
            }
            .menuIndicator(.hidden)
        }
        
        if #available(iOS 26.0, macOS 26.0, *) {
            ToolbarSpacer()
        }
        
        if !viewModel.isSelecting {
            ToolbarItem(placement: .primaryAction) {
                Button("ADD_GAMES", systemImage: "plus", action: self.addGames)
            }
        }
        
        #if !os(macOS)
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink("SETTINGS", systemImage: "gear", to: .settings)
        }
        if viewModel.isSelecting {
            ToolbarItemGroup(placement: .bottomBar) {
                let hasSelection = viewModel.selection.isEmpty
                
                ToggleButton("DELETE", systemImage: "trash", role: .destructive, value: $viewModel.isDeleteGamesConfirmationOpen)
                    .disabled(hasSelection)
                    .deleteItem("DELETE_GAMES", isPresented: $viewModel.isDeleteGamesConfirmationOpen, perform: deleteGames) {
                        Text("DELETE_GAMES_MESSAGE")
                    }

                Spacer()

                Button("MANAGE_TAGS", systemImage: "tag", action: manageTags)
                    .disabled(hasSelection)
            }

            ToolbarItem(placement: .confirmationAction) {
                ConfirmButton("DONE", action: finishSelection)
            }
        }
        #endif
    }
}

extension LibraryView {
    private func addGames() {
        viewModel.fileImportRequest = .roms(multiple: true, completion: handleUploadedRoms)
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
}

extension LibraryView {
    private func deleteGames() async {
        let boxes = viewModel.selection.map(ObjectBox.init)
        do {
            try await persistence.objects.deleteMany(boxes)
        } catch {
            // FIXME: Surface error
            print(error)
        }
    }
    
    private func manageTags() {
        viewModel.manageTagsTarget = if viewModel.selection.count == 1 {
            .one(viewModel.selection.first!)
        } else {
            .many(viewModel.selection)
        }
    }
    
    private func finishSelection() {
        withAnimation {
            viewModel.isSelecting = false
            viewModel.selection.removeAll()
        }
    }
}

extension LibraryView {
    private func updatePredicate<T>(_: T) {
        games.nsPredicate = viewModel.predicate(for: viewModel.query)
    }
    
    private func updateSortDescriptor<T>(_: T) {
        games.nsSortDescriptors = LibraryViewModel.getSortDescriptors(settings: settings)
    }
}

extension LibraryView {
    private static let keepPlayingFetchRequest: NSFetchRequest = {
        let fetchRequest = SaveStateObject.fetchRequest()
        fetchRequest.fetchLimit = 10
        fetchRequest.sortDescriptors = [.init(keyPath: \SaveStateObject.date, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "isAuto == true")
        return fetchRequest
    }()
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    NavigationStack {
        LibraryView()
    }
    .environmentObject(CoreRegistry())
    .environmentObject(Settings())
}
