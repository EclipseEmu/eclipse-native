import Combine
import CoreData
import EclipseKit
import Foundation
import SwiftUI

struct CheatsView: View {
    static let sortCheatsBy = [NSSortDescriptor(keyPath: \CheatObject.priority, ascending: true)]

    @EnvironmentObject var persistence: Persistence
    @EnvironmentObject var coreRegistry: CoreRegistry
    @Environment(\.dismiss) var dismiss: DismissAction

    @ObservedObject private var game: GameObject
    @State private var cheatFormats: [CoreCheatFormat] = []
    @State private var editorTarget: EditorTarget<CheatObject>?

    @FetchRequest(sortDescriptors: Self.sortCheatsBy) var cheats: FetchedResults<CheatObject>

    init(game: GameObject) {
        self.game = game
        let request = CheatObject.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.includesSubentities = false
        request.sortDescriptors = Self.sortCheatsBy
        self._cheats = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        self.content
            .onAppear {
                self.cheatFormats = coreRegistry.cheatFormats(for: game)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton("DONE", action: dismiss.callAsFunction)
                }
                
#if !os(macOS)
                ToolbarItem(content: EditButton.init)
#endif
                ToolbarItem(placement: .primaryAction) {
                    Button("ADD_CHEAT", systemImage: "plus") {
                        editorTarget = .create
                    }
                    .disabled(self.cheatFormats.isEmpty)
                }
            }
            .navigationTitle("CHEATS")
            .sheet(item: $editorTarget) { target in
                CheatEditorView(
                    target: target,
                    game: game,
                    cheatFormats: cheatFormats
                )
            }
    }
    
    @ViewBuilder
    var content: some View {
        if cheatFormats.isEmpty {
            ContentUnavailableMessage("NO_SUPPORTED_CHEATS_TITLE", systemImage: "nosign", description: "NO_SUPPORTED_CHEATS_MESSAGE")
        } else if cheats.isEmpty {
            ContentUnavailableMessage(
                "NO_CHEATS_TITLE",
                systemImage: "memorychip.fill",
                description: "NO_CHEATS_MESSAGE \(game.name ?? String(localized: "GAME_UNNAMED"))"
            )
        } else {
            List {
                ForEach(self.cheats) { cheat in
                    CheatItemView(cheat: cheat, editorTarget: $editorTarget)
                }
                .onDelete(perform: self.deleteCheats)
                .onMove(perform: self.moveCheat)
            }
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
            CheatsView(game: game)
        }
    }
}
