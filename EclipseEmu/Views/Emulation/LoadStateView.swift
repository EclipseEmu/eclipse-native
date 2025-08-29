import SwiftUI
import EclipseKit

typealias Foo = Void

struct LoadStateView<Core: CoreProtocol>: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    @ObservedObject private var viewModel: EmulationViewModel<Core>

    init(viewModel: EmulationViewModel<Core>) {
        self.viewModel = viewModel
    }

    var body: some View {
        SaveStatesView(game: viewModel.game, action: selected)
            .navigationTitle("LOAD_SAVE_STATE")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton(action: dismiss.callAsFunction)
                }
            }
    }

    private func selected(_ saveState: SaveStateObject) {
        let url = viewModel.persistence.files.url(for: saveState.path)
        Task {
            await loadState(url)
            dismiss()
        }
    }
    
    // NOTE: This is seperate from `selected` because the compiler doesn't think the return type is sendable... when its Void?
    private func loadState(_ url: URL) async {
        do {
            try await viewModel.coordinator.loadState(from: url)
        } catch {
            // FIXME: Surface error
            print("failed to load save state:", error)
        }
    }
}
