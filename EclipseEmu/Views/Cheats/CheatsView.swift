import Combine
import CoreData
import EclipseKit
import Foundation
import SwiftUI

struct CheatsView: View {
    static let sortCheatsBy = [NSSortDescriptor(keyPath: \CheatObject.priority, ascending: true)]

    @ObservedObject var game: GameObject
    let cheatFormats: [CoreCheatFormat]
    @Environment(\.managedObjectContext) var viewContext: NSManagedObjectContext
    @Environment(\.dismiss) var dismiss: DismissAction
    @EnvironmentObject var persistence: Persistence
    @FetchRequest(sortDescriptors: Self.sortCheatsBy) var cheats: FetchedResults<CheatObject>
    @State var isAddViewOpen = false
    @State var editingCheat: CheatObject?

    init(game: GameObject, coreRegistry: CoreRegistry) {
        self.game = game

		self.cheatFormats = coreRegistry.cheatFormats(for: game)

        let request = CheatObject.fetchRequest()
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
                Label("NO_CHEATS_TITLE", systemImage: "memorychip.fill")
            } description: {
                Text("NO_CHEATS_MESSAGE \(game.name ?? String(localized: "GAME_UNNAMED"))")
            }
        }
        .emptyState(cheatFormats.isEmpty) {
            ContentUnavailableMessage {
                Label("NO_SUPPORTED_CHEATS_TITLE", systemImage: "nosign")
            } description: {
                Text("NO_SUPPORTED_CHEATS_MESSAGE")
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                CancelButton("DONE", action: dismiss.callAsFunction)
            }
            
#if !os(macOS)
            ToolbarItem {
                EditButton()
            }
#endif
            ToolbarItem(placement: .primaryAction) {
                ToggleButton(value: $isAddViewOpen) {
                    Label("ADD_CHEAT", systemImage: "plus")
                }
                .disabled(self.cheatFormats.isEmpty)
            }
        }
        .navigationTitle("CHEATS")
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
                // FIXME: Surface error
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
#Preview(traits: .previewStorage) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        NavigationStack {
            CheatsView(game: game, coreRegistry: .init())
        }
    }
}
