import Foundation
import SwiftUI
import EclipseKit
import Combine

struct CheatsView: View {
    static let sortCheatsBy = [NSSortDescriptor(keyPath: \Cheat.priority, ascending: true)]
    
    var game: Game
    let cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.persistenceCoordinator) var persistence
    @FetchRequest(sortDescriptors: Self.sortCheatsBy) var cheats: FetchedResults<Cheat>
    @State var isAddViewOpen = false
    @State var editingCheat: Cheat?
    
    init(game: Game) {
        self.game = game

        let core = EclipseEmuApp.cores.get(for: game)!
        self.cheatFormats = UnsafeBufferPointer(start: core.cheatFormats, count: core.cheatFormatsCount)
        
        let request = CheatManager.listRequest(for: game)
        request.sortDescriptors = Self.sortCheatsBy
        self._cheats = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        Group {
            if self.cheats.count == 0 {
                ScrollView {
                    MessageBlock {
                        Text("No Cheats")
                            .fontWeight(.medium)
                            .padding([.top, .horizontal], 8.0)
                        Text("You haven't added any cheats for \(game.name ?? "this game"). Use the \(Image(systemName: "plus")) button to add cheats.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding([.bottom, .horizontal], 8.0)
                    }
                }
            } else {
                List {
                    ForEach(self.cheats) { cheat in
                        CheatItemView(cheat: cheat, editingCheat: $editingCheat)
                    }
                    .onDelete(perform: self.deleteCheats)
                    .onMove(perform: self.moveCheat)
                }
            }
        }.toolbar {
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
        try? viewContext.save()
    }
    
    func deleteCheats(offsets: IndexSet) {
        for index in offsets {
            let cheat = cheats[index]
            try? CheatManager.delete(cheat: cheat, in: self.persistence, save: false)
        }
        try? viewContext.save()
    }
}

#if DEBUG
#Preview {
    let context = PersistenceCoordinator.preview.container.viewContext
    let game = Game(context: context)
    game.system = .gba
    
    return CheatsView(game: game)
        .environment(\.managedObjectContext, context)
}
#endif
