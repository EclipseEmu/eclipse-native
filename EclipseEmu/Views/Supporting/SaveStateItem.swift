import SwiftUI

struct SaveStateItem: View {
    @Environment(\.persistenceCoordinator) var persistence
    
    var saveState: SaveState
    var action: (SaveState) -> Void
    
    init(saveState: SaveState, action: @escaping (SaveState) -> Void) {
        self.saveState = saveState
        self.action = action
    }
    
    var body: some View {
        Button {
            self.action(self.saveState)
        } label: {
            VStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8.0)
                    .aspectRatio(1.5, contentMode: .fit)
                Text("\(saveState.isAuto ? "Auto" : "Manual") · \(saveState.date ?? .now, format: .dateTime)")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: self.deleteSaveState) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func deleteSaveState() {
        do {
            try persistence.external.deleteSaveState(for: self.saveState)
            persistence.context.delete(self.saveState)
            persistence.save()
        } catch {
            print(error)
        }
    }
}
