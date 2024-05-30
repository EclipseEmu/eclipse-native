import SwiftUI

struct GameListMenuItems: View {
    @ObservedObject var viewModel: GameListViewModel

    var body: some View {
        Group {
            Button {
                withAnimation {
                    viewModel.selection.removeAll()
                    viewModel.isSelecting = true
                }
            } label: {
                Label("Select", systemImage: "checkmark.circle")
            }

            Divider()

            Picker("Display Mode", selection: $viewModel.displayMode) {
                ForEach(GameListViewModel.DisplayMode.allCases) { displayMode in
                    displayMode.label.tag(displayMode)
                }
            }

            Divider()

            Section("Sort by...") {
                Picker("Sort Method", selection: $viewModel.sortMethod) {
                    ForEach(GameListViewModel.SortMethod.allCases) { method in
                        Text(method.displayName)
                            .tag(method)
                    }
                }
                Picker("Sort Direction", selection: $viewModel.sortDirection) {
                    ForEach(GameListViewModel.SortDirection.allCases) { direction in
                        Text(direction.displayName)
                            .tag(direction)
                    }
                }
            }
        }
    }
}

#Preview {
    Menu {
        GameListMenuItems(viewModel: .init(filter: .none))
    } label: {
        Text("Menu")
    }
}
