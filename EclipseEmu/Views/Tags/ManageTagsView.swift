import SwiftUI

enum ManageTagsTarget: Identifiable, Hashable {
    var id: Int { self.hashValue }

    case one(GameObject)
    case many(Set<GameObject>)
}

private struct TagsSelection {
    let game: GameObject
    var isSelected: Bool

    init(game: GameObject, tag: TagObject) {
        self.game = game
        isSelected = game.tags?.contains(tag) ?? false
    }
}

// MARK: Helper Views

private struct ManyManageTagsItemView: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject private var tag: TagObject
    let games: [ObjectBox<GameObject>]
    @State private var sources: [TagsSelection]
    @Binding private var error: PersistenceError?

    init(tag: TagObject, target: Set<GameObject>, error: Binding<PersistenceError?>) {
        self.tag = tag
        self.games = target.boxedItems()
        self._error = error
        sources = target.map { TagsSelection(game: $0, tag: tag) }
    }

    var body: some View {
        Toggle(sources: $sources, isOn: \.isSelected) {
            Label(tag.name ?? "TAG", systemImage: "tag")
        }
        .onChange(of: sources.first?.isSelected ?? false, perform: update)
        .listItemTint(tag.color.color)
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
    @ObservedObject private var tag: TagObject
    @ObservedObject private var game: GameObject
    @State private var isOn: Bool
    @Binding private var error: PersistenceError?

    init(tag: TagObject, game: GameObject, error: Binding<PersistenceError?>) {
        self.tag = tag
        self.game = game
        self.isOn = game.tags?.contains(tag) ?? false
        self._error = error
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(tag.name ?? "TAG", systemImage: "tag")
        }
        .onChange(of: isOn, perform: update)
        .listItemTint(tag.color.color)
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

    @FetchRequest<TagObject>(sortDescriptors: [NSSortDescriptor(keyPath: \TagObject.name, ascending: true)])
    private var tags: FetchedResults<TagObject>

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
                Button("NEW_TAG", action: newTag)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("DONE", action: dismiss.callAsFunction)
            }
        }
        .alert(isPresented: .isSome($error), error: error) {
            Button("OK", role:  .cancel) {}
        }
        .navigationTitle("MANAGE_TAGS")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $isNewTagViewOpen) {
            FormSheetView {
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
    .environmentObject(Settings())
}
