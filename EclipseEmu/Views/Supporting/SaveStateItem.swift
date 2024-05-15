import SwiftUI

struct SaveStateItem: View {
    @Environment(\.persistenceCoordinator) var persistence
    @Environment(\.dismiss) var dismiss

    var saveState: SaveState
    var action: (SaveState, DismissAction) -> Void
    
    init(saveState: SaveState, action: @escaping (SaveState, DismissAction) -> Void) {
        self.saveState = saveState
        self.action = action
    }
    
    var body: some View {
        Button {
            self.action(self.saveState, self.dismiss)
        } label: {
            VStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8.0)
                    .aspectRatio(1.5, contentMode: .fit)
                Text("\(saveState.isAuto ? "Auto" : "Manual") · \(saveState.date, format: .dateTime)")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: self.deleteSaveState) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func deleteSaveState() {
        do {
            try SaveStateManager.delete(saveState, in: persistence)
        } catch {
            print(error)
        }
    }
}
