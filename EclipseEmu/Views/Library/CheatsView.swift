import Foundation
import SwiftUI
import EclipseKit
import Combine

struct CheatsView: View {
    static let sortCheatsBy = [NSSortDescriptor(keyPath: \Cheat.priority, ascending: true)]
    
    var game: Game
    let cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(sortDescriptors: Self.sortCheatsBy) var cheats: FetchedResults<Cheat>
    @State var isAddViewOpen = false
    @State var editingCheat: Cheat?
    
    init(game: Game) {
        self.game = game

        let core = EclipseEmuApp.cores.get(for: game)!
        self.cheatFormats = UnsafeBufferPointer(start: core.cheatFormats, count: core.cheatFormatsCount)
        
        let request = Cheat.fetchRequest()
        request.sortDescriptors = Self.sortCheatsBy
        request.predicate = NSPredicate(format: "game == %@", self.game)
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
                        Button {
                            self.editingCheat = cheat
                        } label: {
                            Text(cheat.label ?? cheat.code ?? "")
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
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
        // FIXME: This function works, but is painful.
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
            viewContext.delete(cheat)
        }
        try? viewContext.save()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let game = Game(context: context)
    game.system = .gba
    
    return CheatsView(game: game)
        .environment(\.managedObjectContext, context)
}
