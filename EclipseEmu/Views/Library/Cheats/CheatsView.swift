import Foundation
import SwiftUI
import EclipseKit
import Combine

struct CheatsView: View {
    static let sortCheatsBy = [NSSortDescriptor(keyPath: \Cheat.priority, ascending: true)]
    
    @ObservedObject var game: Game
    let cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.persistenceCoordinator) var persistence
    @FetchRequest(sortDescriptors: Self.sortCheatsBy) var cheats: FetchedResults<Cheat>
    @State var isAddViewOpen = false
    @State var editingCheat: Cheat?
    
    init(game: Game) {
        self.game = game

        if let core = EclipseEmuApp.cores.get(for: game) {
            self.cheatFormats = UnsafeBufferPointer(start: core.cheatFormats, count: core.cheatFormatsCount)
        } else {
            self.cheatFormats = UnsafeBufferPointer.init(start: nil, count: 0)
        }
        
        let request = CheatManager.listRequest(for: game)
        request.sortDescriptors = Self.sortCheatsBy
        self._cheats = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        List {
            ForEach(self.cheats) { cheat in
                CheatItemView(cheat: cheat, editingCheat: $editingCheat)
            }
            .onDelete(perform: self.deleteCheats)
            .onMove(perform: self.moveCheat)
        }
        .emptyState(self.cheats.isEmpty) {
            ContentUnavailableMessage {
                Label("No Cheats", systemImage: "doc.badge.gearshape")
            } description: {
                Text("You haven't added any cheats for \(game.name ?? "this game"). Use the \(Image(systemName: "plus")) button to add cheats.")
            }
        }
        .emptyState(self.cheatFormats.isEmpty) {
            ContentUnavailableMessage {
                Label("No Supported Cheats", systemImage: "nosign")
            } description: {
                Text("You can't add cheats for this game. The core it uses doesn't support any cheat formats.")
            }
        }
        .toolbar {
            #if !os(macOS)
            ToolbarItem {
                EditButton()
            }
            #endif
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    self.isAddViewOpen = true
                } label: {
                    Label("Add Cheat", systemImage: "plus")
                }
                .disabled(self.cheatFormats.isEmpty)
            }
        }
        .navigationTitle("Cheats")
        .sheet(item: $editingCheat) { cheat in
            EditCheatView(
                cheat: cheat,
                game: game,
                cheatFormats: cheatFormats
            )
        }
        .sheet(isPresented: $isAddViewOpen) {
            EditCheatView(
                cheat: nil,
                game: game,
                cheatFormats: cheatFormats
            )
        }
    }
    
    func moveCheat(fromOffsets: IndexSet, toOffset: Int) -> Void {
        // FIXME: This function works, but is painful as it clones. This could definately be optimized.
        var cheatsArray = cheats.map { $0 }
        cheatsArray.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (i, cheat) in cheatsArray.enumerated() {
            cheat.priority = Int16(truncatingIfNeeded: i)
        }
        persistence.saveIfNeeded()
    }
    
    func deleteCheats(offsets: IndexSet) {
        for index in offsets {
            let cheat = cheats[index]
            try? CheatManager.delete(cheat: cheat, in: self.persistence, save: false)
        }
        persistence.saveIfNeeded()
    }
}

#if DEBUG
#Preview {
    let context = PersistenceCoordinator.preview.container.viewContext
    let game = Game(context: context)
    game.system = .gba
    
    return CompatNavigationStack {
        CheatsView(game: game)
    }
    .environment(\.managedObjectContext, context)
}
#endif
