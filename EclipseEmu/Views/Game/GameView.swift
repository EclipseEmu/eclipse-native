import SwiftUI

private struct HeaderBackground: View {
    private let coordinateSpace: CoordinateSpace
    private let color: Color

    init(in coordinateSpace: CoordinateSpace, color: Color) {
        self.coordinateSpace = coordinateSpace
        self.color = color
    }

    var body: some View {
        GeometryReader { geo in
            let outer = geo.frame(in: coordinateSpace)
            let minY = outer.minY

            Rectangle()
                .foregroundStyle(Material.ultraThick)
                .background(Color.black.gradient.opacity(0.5))
                .background(color)
                .offset(y: -geo.safeAreaInsets.top + minY > 0 ? -minY : -geo.safeAreaInsets.top)
                .transformEffect(.init(scaleX: 1.0, y: 1.0 + (minY > 0 ? minY / (geo.size.height - minY) : 0)))
                .overlay(alignment: .bottom) {
                    Divider()
                }
        }
    }
}

struct GameView: View {
    private let dateFormatter = RelativeDateTimeFormatter()

    @EnvironmentObject private var playback: GamePlayback
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ObservedObject var game: Game
    @FetchRequest<SaveState>(fetchRequest: SaveState.fetchRequest())
    private var saveStates: FetchedResults<SaveState>
    @State private var coverColor: Color?

    @State private var renameTarget: Game?
    @State private var deleteTarget: Game?
    @State private var renameSaveStateTarget: SaveState?
    @State private var deleteSaveStateTarget: SaveState?
    @State private var coverPickerMethod: CoverPickerMethod?
    @State private var isManageTagsOpen: Bool = false

    init(game: Game, coverColor: Color = .clear) {
        self.game = game

        let request = SaveState.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SaveState.isAuto, ascending: false),
            NSSortDescriptor(keyPath: \SaveState.date, ascending: false)
        ]
        request.fetchLimit = 10

        self._saveStates = .init(fetchRequest: request)
    }

    private var header: some View {
        VStack {
            AverageColorLocalImage(game.cover, color: $coverColor) { image in
                image
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8.0)
                    .foregroundStyle(.secondary)
            }
            .aspectRatio(1.0, contentMode: .fit)
            .frame(maxWidth: 256.0)

            Text(game.name ?? "Game")
                .padding(.top)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(game.system.string)
                .padding(.bottom)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: play) {
                Label("Play Game", systemImage: "play.fill").fontWeight(.semibold)
            }
            .tint(.white)
            .foregroundStyle(.black)
            .tint(.accentColor)
            .buttonStyle(.borderedProminent)
            .modify {
                if #available(macOS 14, *) {
                    $0.buttonBorderShape(.capsule)
                } else {
                    $0
                }
            }
            .controlSize(.large)
        }
        .frame(minWidth: .zero, maxWidth: .infinity)
        .padding(.vertical, 32.0)
    }

    private var saveStatesShelf: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16.0) {
                ForEach(saveStates) { saveState in
                    SaveStateItem(
                        saveState,
                        title: .name,
                        formatter: dateFormatter,
                        renameTarget: $renameSaveStateTarget,
                        deleteTarget: $deleteSaveStateTarget,
                        action: self.saveStateSelected(saveState:)
                    )
                    .frame(height: 226.0)
                }
            }
            .padding([.bottom, .horizontal])
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                header
                    .padding(.top, proxy.safeAreaInsets.top)
                    .background(HeaderBackground(in: .named("scrollView"), color: coverColor ?? .white))

                Section {
                    saveStatesShelf
                        .buttonStyle(.plain)
                        .emptyState(saveStates.isEmpty) {
                            EmptyMessage {
                                Text("No Save States")
                            } message: {
                                Text("You haven't made any save states for this game yet.")
                            }
                            .padding(.bottom)
                        }
                } header: {
                    HStack {
                        Text("Save States")
                            .sectionHeaderStyle()

                        Spacer()

                        NavigationLink(to: .saveStates(game)) {
                            Text("View All")
                                .font(.body)
                        }
                    }
                    .padding([.horizontal, .top])
                }

                Section {
                    VStack(alignment: .leading, spacing: 12.0) {
                        DataPointView(title: "Date Added") {
                            Text(game.dateAdded, format: .dateTime, fallback: "Unknown")
                        }
                        DataPointView(title: "Last Played") {
                            Text(game.datePlayed, format: .dateTime, fallback: "Never")
                        }
                        DataPointView(title: "SHA-1 Checksum") {
                            Text(verbatim: game.sha1, fallback: "Unknown")
                                .font(.caption.monospaced())
                        }
                    }
                    .padding([.horizontal, .bottom])
                } header: {
                    Text("Information")
                        .sectionHeaderStyle()
                        .padding(.horizontal)
                        .padding(.bottom, 4.0)
                }
            }
            .coordinateSpace(name: "scrollView")
            .ignoresSafeArea(edges: .top)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            Menu {
                Button(action: rename) {
                    Label("Rename", systemImage: "text.cursor")
                }

                CoverPickerMenu(game: game, coverPickerMethod: $coverPickerMethod)

                Divider()

                Button(action: manageTags) {
                    Label("Manage Tags", systemImage: "tag")
                }

                NavigationLink(to: .cheats(game)) {
                    Label("Manage Cheats", systemImage: "memorychip")
                }

                Divider()

                Button(action: replaceROM) {
                    Label("Replace ROM", systemImage: "rectangle.2.swap")
                }
                Menu {
                    Button(action: importSave) {
                        Label("Import Save", systemImage: "square.and.arrow.down")
                    }
                    Button(action: exportSave) {
                        Label("Export Save", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive, action: deleteSave) {
                        Label("Delete Save", systemImage: "trash")
                    }
                } label: {
                    Label("Manage Save", systemImage: "doc")
                        .labelStyle(.iconOnly)
                }

                Divider()

                Button(role: .destructive, action: delete) {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Label("Options", systemImage: "ellipsis.circle")
            }
        }
        .sheet(isPresented: $isManageTagsOpen) {
            NavigationStack {
                ManageTagsView(target: .one(game))
            }
        }
        .renameItem("Rename Game", item: $renameTarget)
        .deleteItem("Delete Game", item: $deleteTarget) { game in
            Text("Are you sure you want to delete \(game.name ?? "this game")? Its saves, save states, and cover art will all be deleted. This can't be undone.")
        }
        .renameItem("Rename Save State", item: $renameSaveStateTarget)
        .deleteItem("Delete Save State", item: $deleteSaveStateTarget) { saveState in
            Text("Are you sure you want to delete \(saveState.name ?? "this save state")? This can't be undone.")
        }
        .coverPicker(presenting: $coverPickerMethod)
    }

    private func delete() {
        self.deleteTarget = self.game
    }

    private func rename() {
        self.renameTarget = self.game
    }

    private func manageTags() {
        self.isManageTagsOpen = true
    }

    private func importSave() {
        // FIXME: todo
    }

    private func exportSave() {
        // FIXME: todo
    }

    private func deleteSave() {
        // FIXME: todo
    }

    private func replaceROM() {
        // FIXME: todo
    }

    private func play() {
        Task {
            do {
                try await playback.play(game: game, persistence: persistence)
            } catch {
                // FIXME: Handle error
                print(error)
            }
        }
    }

    private func saveStateSelected(saveState: SaveState) {
        Task {
            do {
                try await playback.play(state: saveState, persistence: persistence)
            } catch {
                // FIXME: Handle error
                print(error)
            }
        }
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        NavigationStack {
            GameView(game: game, coverColor: Color.red)
        }
    }
}
