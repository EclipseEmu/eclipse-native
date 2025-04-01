import SwiftUI

struct LoadStateView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject var game: Game
    let action: (SaveState) -> Void

    var body: some View {
        NavigationStack {
            SaveStatesView(game: game, action: action)
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
}

