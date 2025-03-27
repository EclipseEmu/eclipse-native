import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct GameListToolbarItems: ToolbarContent {
    @ObservedObject var viewModel: GameListViewModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if viewModel.isSelecting {
                Button {
                    viewModel.isSelecting = false
                    viewModel.selection.removeAll()
                } label: {
                    Text("Done")
                }
            }
        }

#if !os(macOS)
        ToolbarItemGroup(placement: .bottomBar) {
            if viewModel.isSelecting {
                Button {
                    viewModel.isDeleteConfirmationOpen = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(viewModel.selection.isEmpty)

                Spacer()

                Button {
                    viewModel.isAddToCollectionOpen = true
                } label: {
                    Label("Add to...", systemImage: "text.badge.plus")
                }
                .disabled(viewModel.selection.isEmpty)
            }
        }
#endif
    }
}

#Preview {
    let viewModel = GameListViewModel(filter: .none)

    return NavigationStack {
        Button("Toggle Selection") {
            viewModel.isSelecting.toggle()
        }
        .navigationTitle("Test")
        .toolbar {
            GameListToolbarItems(viewModel: viewModel)
        }
    }
}
