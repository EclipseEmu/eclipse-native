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
                .background(color)
                .offset(y: -geo.safeAreaInsets.top + minY > 0 ? -minY : -geo.safeAreaInsets.top)
                .transformEffect(.init(scaleX: 1.0, y: 1.0 + (minY > 0 ? minY / (geo.size.height - minY) : 0)))
                .overlay(alignment: .bottom) {
                    Divider()
                }
        }
    }
}

struct GameView2: View {
    private let dateFormatter = RelativeDateTimeFormatter()

    @EnvironmentObject private var playback: GamePlayback
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var game: Game
    @SectionedFetchRequest<Bool, SaveState>(fetchRequest: SaveState.fetchRequest(), sectionIdentifier: \.isAuto)
    private var saveStates: SectionedFetchResults<Bool, SaveState>
    @State private var primaryColor: Color = .clear

    @State private var renameTarget: Game?
    @State private var deleteTarget: Game?
    @State private var isManageTagsOpen: Bool = false

    @State private var coverPickerMethod: CoverPickerMethod?

    init(game: Game) {
        self.game = game

        let request = SaveState.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SaveState.isAuto, ascending: false),
            NSSortDescriptor(keyPath: \SaveState.date, ascending: false)
        ]
        request.fetchLimit = 10

        self._saveStates = .init(fetchRequest: request, sectionIdentifier: \.isAuto)
    }

    @ViewBuilder
    var header: some View {
        VStack {
            LocalImage(game.boxart) { image in
                image
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 8.0))
            } placeholder: {
                RoundedRectangle(cornerRadius: 12.0)
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
                Label("Play Game", systemImage: "play.fill")
                    .fontWeight(.medium)
            }
            .tint(.white)
            .foregroundStyle(.black)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .modify {
                if #available(iOS 16.0, macOS 14.0, *) {
                    $0.buttonBorderShape(.capsule)
                } else {
                    $0
                }
            }
        }
        .frame(minWidth: .zero, maxWidth: .infinity)
        .padding(.vertical, 32.0)
    }

    var saveStatesShelf: some View {
        ForEach(saveStates, id: \.id) { section in
            ForEach(section, id: \.id) { saveState in
                SaveStateItem2(
                    saveState,
                    title: .name,
                    formatter: dateFormatter,
                    action: self.saveStateSelected(saveState:)
                )
            }

            if section.id && saveStates.count > 1 {
                Divider()
            }
        }
    }

    var body: some View {
        GeometryReader { safeAreaPadding in
            ScrollView {
                header
                    .padding(.top, safeAreaPadding.safeAreaInsets.top)
                    .background(HeaderBackground(in: .named("scrollView"), color: primaryColor))

                Section {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 16.0) {
                            saveStatesShelf
                        }
                        .padding([.bottom, .horizontal])
                    }
                    .buttonStyle(.plain)
                } header: {
                    HStack {
                        Text("Save States")
                            .sectionHeaderStyle()
                        Spacer()
                        NavigationLink(to: .saveStates(game)) {
                            Text("View All")
                        }
                    }
                    .padding([.horizontal, .top])
                }
                .fullWidthFrame()

                Section {
                } header: {
                    Text("Information")
                        .sectionHeaderStyle()
                        .padding(.horizontal)
                }
                .fullWidthFrame()
            }
            .coordinateSpace(name: "scrollView")
            .ignoresSafeArea(edges: .top)
        }
        .toolbar {
            Menu {
                Button(action: self.rename) {
                    Label("Rename", systemImage: "text.cursor")
                }

                CoverPickerMenu(game: game, coverPickerMethod: $coverPickerMethod)

                Divider()

                Button(action: self.manageTags) {
                    Label("Manage Tags", systemImage: "tag")
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
            Text("Are you sure you want to delete \(game.name ?? "this game")? Its saves, save states, and box art will all be deleted.")
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

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        NavigationStack {
            GameView2(game: game)
        }
    }
}
