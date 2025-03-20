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

@available(iOS 18.0, macOS 15.0, *)
#Preview("Unchecked", traits: .modifier(PreviewStorage())) {
    let model: GameListViewModel = {
        let model = GameListViewModel(filter: .none)
        model.isSelecting = true
        return model
    }()

    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        VStack {
            Spacer()
            GameListItemSelectionToggle(viewModel: model, game: game)
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(.red)
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview("Checked", traits: .modifier(PreviewStorage())) {
    let model: GameListViewModel = {
        let model = GameListViewModel(filter: .none)
        model.isSelecting = true
        return model
    }()

    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        VStack {
            Spacer()
            GameListItemSelectionToggle(viewModel: model, game: game)
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(.red)
        .onAppear {
            model.selection.insert(game)
        }
    }
}
