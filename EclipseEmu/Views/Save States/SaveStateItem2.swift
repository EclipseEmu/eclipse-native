import SwiftUI

enum SaveStateItemTitle {
    case name
    case game
}

struct SaveStateItem2: View {
    @EnvironmentObject private var persistence: Persistence

    @ObservedObject private var saveState: SaveState
    private let formatter: RelativeDateTimeFormatter
    private let titleValue: SaveStateItemTitle
    private let action: (SaveState) -> Void

    init(
        _ saveState: SaveState,
        title: SaveStateItemTitle,
        formatter: RelativeDateTimeFormatter,
        action: @escaping (SaveState) -> Void
    ) {
        self.saveState = saveState
        self.formatter = formatter
        self.titleValue = title
        self.action = action
    }

    var title: Text {
        switch titleValue {
        case .name:
            Text(saveState.name ?? (saveState.isAuto ? "Automatic State" : "Unnamed State"))
        case .game:
            Text(saveState.game?.name ?? "Game")
        }
    }

    var body: some View {

        Button {
            self.action(self.saveState)
        } label: {
            DualLabeledImage(
                title: title,
                subtitle: Text(saveState.date ?? Date(), formatter: formatter)
            ) {
                LocalImage(saveState.preview) { image in
                    image
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12.0)
                        .foregroundStyle(.secondary)
                }
                .aspectRatio(3 / 2, contentMode: .fit)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 226.0)
        .contextMenu {
            if let game = saveState.game {
                NavigationLink(to: .game(game)) {
                    Label("Go to Game", systemImage: "arrow.right.square")
                }
            }
        }
    }

    private func selected() {
        self.action(self.saveState)
    }
}
