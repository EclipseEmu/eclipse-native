import CoreData
import EclipseKit
import SwiftUI
import UniformTypeIdentifiers

private enum LibraryViewError: LocalizedError {
    case gameManager(GameError)
    case playAction(PlayGameError)

    var errorDescription: String? {
        switch self {
        case .gameManager(let error): error.errorDescription
        case .playAction(let error): error.errorDescription
        }
    }
}

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct LibraryView: View {
    static let recentlyPlayedRequest: NSFetchRequest<SaveState> = {
        let request = SaveState.fetchRequest()
        request.fetchLimit = 10
        request.predicate = NSPredicate(format: "isAuto == true")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SaveState.date, ascending: false)
        ]
        return request
    }()

    static let romFileTypes: [UTType] = [.romGB, .romGBC, .romGBA, .romNES, .romSNES]

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.playGame) private var playGame
    @StateObject private var viewModel: GameListViewModel = .init(filter: .none)

    @State private var isRomPickerOpen: Bool = false
    @State private var isErrorDialogOpen = false
    @State private var error: LibraryViewError?

    @FetchRequest(
        fetchRequest: Self.recentlyPlayedRequest,
        animation: .default
    )
    private var recentlyPlayed: FetchedResults<SaveState>

    var body: some View {
        NavigationStack {
            ScrollView {
                Section {
                    GameKeepPlayingScroller(
                        saveStates: self.recentlyPlayed,
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

    private func fileImported(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task.detached(priority: .userInitiated) {
                guard url.startAccessingSecurityScopedResource() else {
                    return await self.reportError(error: .gameManager(.failedToGetReadPermissions))
                }
                defer { url.stopAccessingSecurityScopedResource() }

                let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType

                let system = if let fileType {
                    GameSystem(fileType: fileType)
                } else {
                    GameSystem.unknown
                }

                guard system != .unknown else {
                    return await self.reportError(error: .gameManager(.unknownFileType))
                }

                let (name, romExtension) = url.fileNameAndExtension()

                do {
                    try await persistence.objects.createGame(
                        name: name,
                        system: system,
                        romPath: url,
                        romExtension: romExtension
                    )
                } catch {
                    return await self.reportError(error: .gameManager(error as! GameError))
                }
            }
        case .failure(let err):
            print(err)
        }
    }

    private func onPlayFailure(error: PlayGameError, game: Game) {
        print(error, game)
        self.reportError(error: .playAction(error))
    }

    @MainActor
    private func reportError(error: LibraryViewError) {
        self.error = error
        self.isErrorDialogOpen = true
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    LibraryView()
}

