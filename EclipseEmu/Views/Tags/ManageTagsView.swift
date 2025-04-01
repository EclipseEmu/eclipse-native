import SwiftUI

enum ManageTagsTarget: Identifiable, Hashable {
    var id: Int {
        self.hashValue
    }

    case one(Game)
    case many(Set<Game>)
}

private struct TagsSelection {
    var game: Game
    var tag: Tag
    // FIXME: Toggle on library actor instead.
    var isSelected: Bool {
        didSet {
            if isSelected {
                game.addToTags(tag)
            } else {
                game.removeFromTags(tag)
            }
        }
    }

    init(game: Game, tag: Tag) {
        self.game = game
        self.tag = tag
        isSelected = self.game.tags?.contains(tag) ?? false
    }
}

// MARK: Helper Views

private struct ManyManageTagsItemView: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject private var tag: Tag
    @State private var sources: [TagsSelection]

    init(tag: Tag, target: Set<Game>) {
        self.tag = tag
        sources = target.map { TagsSelection(game: $0, tag: tag) }
    }

    var body: some View {
        Toggle(sources: $sources, isOn: \.isSelected) {
            Label(tag.name ?? "Tag", systemImage: "tag")
                .tint(tag.color.color)
        }
    }
}

private struct OneManageTagsItemView: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject var tag: Tag
    @Binding var isOn: Bool

    init(tag: Tag, game: Game) {
        self.tag = tag

        // FIXME: Toggle on library actor instead.
        self._isOn = Binding(get: {
            game.tags?.contains(tag) ?? false
        }, set: { newValue in
            if newValue {
                game.addToTags(tag)
            } else {
                game.removeFromTags(tag)
            }
        })
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(tag.name ?? "Tag", systemImage: "tag")
                .tint(tag.color.color)
        }
    }
}

// MARK: View

struct ManageTagsView: View {
    @EnvironmentObject var persistence: Persistence
    @Environment(\.dismiss) var dismiss: DismissAction

    let target: ManageTagsTarget
    @State private var isNewTagViewOpen: Bool = false

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
                        OneManageTagsItemView(tag: tag, game: game)
                    }
                case .many(let set):
                    ForEach(tags) { tag in
                        ManyManageTagsItemView(tag: tag, target: set)
                    }
                }
            }

            Section {
                Button("New Tag", action: newTag)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Done") {
                    dismiss()
                }
            }
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
