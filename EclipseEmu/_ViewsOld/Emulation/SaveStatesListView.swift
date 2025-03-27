import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct SaveStatesListView: View {
    static let sortDescriptors = [
        NSSortDescriptor(keyPath: \SaveState.isAuto, ascending: false),
        NSSortDescriptor(keyPath: \SaveState.date, ascending: false)
    ]

    @EnvironmentObject var persistence: Persistence
    @Environment(\.dismiss) var dismiss
    @SectionedFetchRequest<Bool, SaveState>(sectionIdentifier: \.isAuto, sortDescriptors: [])
    var saveStates: SectionedFetchResults<Bool, SaveState>
    @State var renameDialogTarget: SaveState?

    var game: Game
    var action: (SaveState) -> Void
    var haveDismissButton: Bool

    init(game: Game, action: @escaping (SaveState) -> Void, haveDismissButton: Bool = false) {
        self.game = game
        self.action = action
        self.haveDismissButton = haveDismissButton

        let request = SaveState.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.includesSubentities = false
        request.sortDescriptors = Self.sortDescriptors
        self._saveStates = SectionedFetchRequest(fetchRequest: request, sectionIdentifier: \.isAuto)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)],
                spacing: 16.0
            ) {
                ForEach(self.saveStates) { section in
                    Section {
                        ForEach(section) { saveState in
                            SaveStateItem(
                                saveState: saveState,
                                action: self.action,
                                renameDialogTarget: $renameDialogTarget
                            )
                        }
                    } header: {
                        SectionHeader(section.id ? "Automatic" : "Manual")
                    }
                }
            }
            .padding()
            .emptyState(self.saveStates.isEmpty) {
                ContentUnavailableMessage {
                    Label("No Save States", systemImage: "doc.on.doc")
                } description: {
                    Text("You haven't made any save states for \(game.name ?? "this game"). Use the \"Save State\" button in the emulation menu to create some.")
                }
            }
        }
        .renameItemAlert(
            $renameDialogTarget,
            key: \.name,
            title: "Rename State",
            placeholder: "State Name",
            onChange: rename
        )
        .modify {
            if haveDismissButton {
                $0.toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                    }
                }
            } else {
                $0
            }
        }
    }

    func rename(saveState: SaveState, newName: String) {
        Task {
            do {
                try await persistence.objects.rename(.init(saveState), to: newName)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
}
