import mGBAEclipseCore
import SwiftUI

#if os(macOS)
struct SidebarView: View {
    enum Selection: Hashable {
        case library
        case collection(GameCollection)
    }

    @Environment(\.persistenceCoordinator) var persistence
    @Binding var selection: Self.Selection
    @State var isCreateCollectionOpen = false

    @FetchRequest<GameCollection>(sortDescriptors: [NSSortDescriptor(keyPath: \GameCollection.name, ascending: true)])
    var collections: FetchedResults<GameCollection>

    var body: some View {
        List(selection: $selection) {
            Section {
                Label("Library", systemImage: "books.vertical")
                    .tag(Selection.library)
            }

            Section("Collections") {
                ForEach(collections) { collection in
                    Label {
                        Text(verbatim: collection.name ?? "Collection")
                    } icon: {
                        CollectionIconView(icon: collection.icon)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            CollectionManager.delete(collection, in: persistence)
                        } label: {
                            Label("Delete Collection", systemImage: "trash")
                        }
                    }
                    .tag(Selection.collection(collection))
                }

                Button {
                    isCreateCollectionOpen = true
                } label: {
                    Label("Create Collection", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
        }
        .sheet(isPresented: $isCreateCollectionOpen) {
            EditCollectionView()
            #if os(macOS)
                .frame(minWidth: 240.0, idealWidth: 500.0, minHeight: 240.0, idealHeight: 600.0)
            #endif
        }
    }
}
#endif

@main
struct EclipseEmuApp: App {
    // FIXME: once the models are finalized, make this use shared
    let persistenceCoordinator = PersistenceCoordinator.preview
    @StateObject var playGameAction = PlayGameAction()
    static let cores: GameCoreRegistry = {
        let mGBACore = mGBAEclipseCore.coreInfo
        let registry = GameCoreRegistry(cores: [mGBACore])
        registry.registerDefaults(id: mGBACore.id, for: .gba)
        return registry
    }()

    #if os(macOS)
    @State var selection: SidebarView.Selection = .library
    #endif

    var body: some Scene {
        WindowGroup {
            if let model = self.playGameAction.model {
                EmulationView(model: model)
            } else {
                #if !os(macOS)
                TabView {
                    LibraryView()
                        .tabItem {
                            Label("Library", systemImage: "books.vertical")
                        }
                    GameCollectionsView()
                        .tabItem {
                            Label("Collections", systemImage: "square.stack")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                #else
                NavigationSplitView {
                    SidebarView(selection: $selection)
                } detail: {
                    switch selection {
                    case .library:
                        LibraryView()
                    case .collection(let gameCollection):
                        GameCollectionView(collection: gameCollection)
                    }
                }
                #endif
            }
        }
        .environment(\.managedObjectContext, persistenceCoordinator.container.viewContext)
        .environment(\.persistenceCoordinator, persistenceCoordinator)
        .environment(\.playGame, playGameAction)

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, persistenceCoordinator.container.viewContext)
                .environment(\.persistenceCoordinator, persistenceCoordinator)
                .environment(\.playGame, playGameAction)
        }
        #endif
    }
}
