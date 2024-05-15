import SwiftUI

struct SaveStatesListView: View {
    static let sortDescriptors = [
        NSSortDescriptor(keyPath: \SaveState.isAuto, ascending: false),
        NSSortDescriptor(keyPath: \SaveState.date, ascending: false)
    ]
    
    @FetchRequest<SaveState>(sortDescriptors: Self.sortDescriptors) var saveStates: FetchedResults<SaveState>
    var game: Game
    var action: (SaveState) -> Void
    var haveDismissButton: Bool
    
    init(game: Game, action: @escaping (SaveState) -> Void, haveDismissButton: Bool = false) {
        self.game = game
        self.action = action
        self.haveDismissButton = haveDismissButton
        
        let request = SaveStateManager.listRequest(for: game, limit: nil)
        request.sortDescriptors = Self.sortDescriptors
        self._saveStates = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        ScrollView {
            if self.saveStates.count == 0 {
                MessageBlock {
                    Text("No Save States")
                        .fontWeight(.medium)
                        .padding([.top, .horizontal], 8.0)
                    Text("You haven't made any save states for \(game.name ?? "this game"). Use the \"Save State\" button in the emulation menu create some.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding([.bottom, .horizontal], 8.0)
                }
            } else {
                LazyVGrid(columns: [.init(.adaptive(minimum: 160.0, maximum: 240.0), spacing: 16.0, alignment: .top)], spacing: 16.0) {
                    ForEach(self.saveStates) { saveState in
                        SaveStateItem(saveState: saveState, action: self.action)
                    }
                }.padding()
            }
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
