import SwiftUI

struct SaveStatesListView: View {
    static let sortDescriptors = [
        NSSortDescriptor(keyPath: \SaveState.isAuto, ascending: false),
        NSSortDescriptor(keyPath: \SaveState.date, ascending: false)
    ]
    
    @Environment(\.persistenceCoordinator) var persistence
    @SectionedFetchRequest<Bool, SaveState>(sectionIdentifier: \.isAuto, sortDescriptors: Self.sortDescriptors) var saveStates: SectionedFetchResults<Bool, SaveState>
    @State var isRenameDialogOpen = false
    @State var renameDialogText: String = ""
    @State var renameDialogTarget: SaveState?
    
    var game: Game
    var action: (SaveState, DismissAction) -> Void
    var haveDismissButton: Bool
    
    init(game: Game, action: @escaping (SaveState, DismissAction) -> Void, haveDismissButton: Bool = false) {
        self.game = game
        self.action = action
        self.haveDismissButton = haveDismissButton
        
        let request = SaveStateManager.listRequest(for: game, limit: nil)
        request.sortDescriptors = Self.sortDescriptors
        self._saveStates = SectionedFetchRequest(fetchRequest: request, sectionIdentifier: \.isAuto)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)], spacing: 16.0) {
                ForEach(self.saveStates) { section in
                    Section {
                        ForEach(section) { saveState in
                            SaveStateItem(saveState: saveState, action: self.action, renameDialogTarget: $renameDialogTarget)
                        }
                    } header: {
                        SectionHeader(section.id ? "Automatic" : "Manual")
                    }
                }
            }
            .padding()
            .emptyMessage(self.saveStates.isEmpty) {
                Text("No Save States")
            } message: {
                Text("You haven't made any save states for \(game.name ?? "this game"). Use the \"Save State\" button in the emulation menu to create some.")
            }
        }
        .onChange(of: renameDialogTarget, perform: { saveState in
            if let saveState {
                self.renameDialogText = saveState.name ?? ""
                self.isRenameDialogOpen = true
            } else {
                self.renameDialogText = ""
            }
        })
        .alert("Rename State", isPresented: $isRenameDialogOpen) {
            Button("Cancel", role: .cancel) {
                self.renameDialogTarget = nil
                self.renameDialogText = ""
            }
            Button("Rename") {
                print("rename")
                guard let renameDialogTarget else { return }
                SaveStateManager.rename(renameDialogTarget, to: renameDialogText, in: persistence)
                self.renameDialogTarget = nil
            }
            TextField("State Name", text: $renameDialogText)
        }
        .modify {
            if haveDismissButton {
                $0.toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        DismissButton()
                    }
                }
            } else {
                $0
            }
        }
    }
}
