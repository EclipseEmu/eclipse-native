import SwiftUI

struct LoadStateView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject var game: Game
    let action: (SaveState) async -> Bool

    var body: some View {
        NavigationStack {
            SaveStatesView(game: game, action: saveStateSelected)
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .navigationTitle("Load State")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel, action: dismiss.callAsFunction)
                    }
                }
        }
    }

    func saveStateSelected(_ saveState: SaveState) {
        Task {
            guard await self.action(saveState) else { return }
            dismiss()
        }
    }
}

