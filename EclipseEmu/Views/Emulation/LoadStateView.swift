import SwiftUI

struct LoadStateView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject var game: GameObject
    let action: (SaveStateObject) async -> Void

    var body: some View {
        FormSheetView {
            SaveStatesView(game: game, action: saveStateSelected)
                .navigationTitle("LOAD_SAVE_STATE")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        CancelButton(action: dismiss.callAsFunction)
                    }
                }
        }
    }

    func saveStateSelected(_ saveState: SaveStateObject) {
        Task {
            await self.action(saveState)
            dismiss()
        }
    }
}

