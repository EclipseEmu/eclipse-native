import Combine
import EclipseKit
import Foundation
import SwiftUI

struct CheatsView: View {
    static let sortCheatsBy = [NSSortDescriptor(keyPath: \Cheat.priority, ascending: true)]

    @ObservedObject var game: Game
    let cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var persistence: Persistence
    @FetchRequest(sortDescriptors: Self.sortCheatsBy) var cheats: FetchedResults<Cheat>
    @State var isAddViewOpen = false
    @State var editingCheat: Cheat?

    init(game: Game) {
        self.game = game

//        if let core = EclipseEmuApp.cores.get(for: game) {
//            self.cheatFormats = UnsafeBufferPointer(start: core.cheatFormats, count: core.cheatFormatsCount)
//        } else {
            self.cheatFormats = UnsafeBufferPointer(start: nil, count: 0)
//        }

        let request = Cheat.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.includesSubentities = false
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
        .emptyState(cheats.isEmpty) {
            ContentUnavailableMessage {
                Label("No Cheats", systemImage: "memorychip.fill")
            } description: {
                Text("You haven't added any cheats for \(game.name ?? "this game"). Use the \(Image(systemName: "plus")) button to add cheats.")
            }
        }
        .emptyState(cheatFormats.isEmpty) {
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

    func moveCheat(fromOffsets: IndexSet, toOffset: Int) {
        let cheats = cheats.map { ObjectBox($0) }
        Task {
            do {
                try await persistence.objects.reorderCheatPriority(cheats: cheats)
            } catch {
                // FIXME: Surface errors
                print(error)
            }
        }
    }

    func deleteCheats(offsets: IndexSet) {
        let cheats = cheats.boxedItems(for: offsets)
        Task {
            do {
                try await persistence.objects.deleteMany(cheats)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        NavigationStack {
            CheatsView(game: game)
        }
    }
}
