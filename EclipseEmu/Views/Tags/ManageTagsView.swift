import SwiftUI

enum ManageTagsTarget: Identifiable, Hashable {
    var id: Int { self.hashValue }

    case one(Game)
    case many(Set<Game>)
}

private struct TagsSelection {
    let game: Game
    var isSelected: Bool

    init(game: Game, tag: Tag) {
        self.game = game
        isSelected = game.tags?.contains(tag) ?? false
    }
}

// MARK: Helper Views

private struct ManyManageTagsItemView: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject private var tag: Tag
    let games: [ObjectBox<Game>]
    @State private var sources: [TagsSelection]
    @Binding private var error: PersistenceError?

    init(tag: Tag, target: Set<Game>, error: Binding<PersistenceError?>) {
        self.tag = tag
        self.games = target.boxedItems()
        self._error = error
        sources = target.map { TagsSelection(game: $0, tag: tag) }
    }

    var body: some View {
        Toggle(sources: $sources, isOn: \.isSelected) {
            Label(tag.name ?? "Tag", systemImage: "tag")
                .tint(tag.color.color)
        }
        .onChange(of: sources.first?.isSelected ?? false, perform: update)
    }

    private func update(_ isEnabled: Bool) {
        Task {
            do {
                try await persistence.objects.toggle(for: .init(tag), state: isEnabled, games: games)
            } catch {
                // FIXME(swiftlang): Swift 6 bug, it knows the error is a PersistenceError... but doesn't?
                self.error = .some(error as! PersistenceError)
            }
        }
    }
}

private struct OneManageTagsItemView: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject private var tag: Tag
    @ObservedObject private var game: Game
    @State private var isOn: Bool
    @Binding private var error: PersistenceError?

    init(tag: Tag, game: Game, error: Binding<PersistenceError?>) {
        self.tag = tag
        self.game = game
        self.isOn = game.tags?.contains(tag) ?? false
        self._error = error
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(tag.name ?? "Tag", systemImage: "tag")
                .tint(tag.color.color)
        }
        .onChange(of: isOn, perform: update)
    }

    private func update(_ newValue: Bool) {
        Task {
            do {
                try await persistence.objects.toggleTag(tag: .init(tag), for: .init(game))
            } catch {
                // FIXME(swiftlang): Swift 6 bug, it knows the error is a PersistenceError... but doesn't?
                self.error = .some(error as! PersistenceError)
            }
        }
    }
}

// MARK: View

struct ManageTagsView: View {
    @EnvironmentObject var persistence: Persistence
    @Environment(\.dismiss) var dismiss: DismissAction

    let target: ManageTagsTarget
    @State private var isNewTagViewOpen: Bool = false
    @State private var error: PersistenceError?

    @FetchRequest<Tag>(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    private var tags: FetchedResults<Tag>

    init(target: ManageTagsTarget) {
        self.target = target
    }

    var body: some View {
        List {
            Section {
                switch target {
                case .one(let game):
                    ForEach(tags) { tag in
                        OneManageTagsItemView(tag: tag, game: game, error: $error)
                    }
                case .many(let set):
                    ForEach(tags) { tag in
                        ManyManageTagsItemView(tag: tag, target: set, error: $error)
                    }
                }
            }

            Section {
                Button("New Tag", action: newTag)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Done", action: dismiss.callAsFunction)
            }
        }
        .alert(isPresented: .isSome($error), error: error) {
            Button("OK", role:  .cancel) {}
        }
        .navigationTitle("Manage Tags")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $isNewTagViewOpen) {
            NavigationStack {
                TagDetailView(mode: .create)
            }
        }
    }

    private func newTag() {
        self.isNewTagViewOpen = true
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
}
