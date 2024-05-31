import SwiftUI

struct GameListItemSelectionToggle: View {
    @ObservedObject var viewModel: GameListViewModel
    @ObservedObject var game: Game

    var body: some View {
        let isSelected = viewModel.selection.contains(game)
        ZStack {
            Circle()
                .foregroundStyle(isSelected ? AnyShapeStyle(.selection) : AnyShapeStyle(.background))

            Image(systemName: "checkmark")
                .foregroundStyle(.white)
                .imageScale(.small)
                .frame(width: 24, height: 24)
                .opacity(Double(isSelected))

            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.gray.opacity(0.8)))
        }
        .compositingGroup()
        .frame(width: 24, height: 24)
        .opacity(Double(viewModel.isSelecting))
    }
}

#Preview("Unchecked") {
    let model = GameListViewModel(filter: .none)
    model.isSelecting = true

    let persistence = PersistenceCoordinator.preview
    let game = Game(context: persistence.context)

    return VStack {
        Spacer()
        GameListItemSelectionToggle(viewModel: model, game: game)
        Spacer()
    }
    .frame(minWidth: 0, maxWidth: .infinity)
    .background(.red)
}

#Preview("Checked") {
    let model = GameListViewModel(filter: .none)
    model.isSelecting = true

    let persistence = PersistenceCoordinator.preview
    let game = Game(context: persistence.context)
    model.selection.insert(game)

    return VStack {
        Spacer()
        GameListItemSelectionToggle(viewModel: model, game: game)
        Spacer()
    }
    .frame(minWidth: 0, maxWidth: .infinity)
    .background(.red)
}
