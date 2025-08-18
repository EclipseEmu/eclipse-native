import SwiftUI

struct LoadStateView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject var game: GameObject
    let action: (SaveStateObject) async -> Void

    var body: some View {
        NavigationStack {
            SaveStatesView(game: game, action: saveStateSelected)
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .navigationTitle("LOAD_SAVE_STATE")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("CANCEL", role: .cancel, action: dismiss.callAsFunction)
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

