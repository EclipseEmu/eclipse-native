import SwiftUI

struct SaveStatesView: View {
    @ObservedObject var model: EmulationViewModel
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SaveStatesListView(game: self.model.game, action: self.saveStateSelected, haveDismissButton: true)
                .navigationTitle("Load State")
#if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    func saveStateSelected(_ state: SaveState) {
        guard case .loaded(let core) = model.state else { return }
        
        let url = persistence.files.url(for: state.path)
        Task.detached {
            _ = await core.loadState(for: url)
            await MainActor.run {
                dismiss()
            }
        }
    }
}
