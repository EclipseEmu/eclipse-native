import SwiftUI
import CoreData

struct KeepPlayingSection: View {
    let saveStateDateFormatter = RelativeDateTimeFormatter()

    @EnvironmentObject var gamePlayback: GamePlayback
    @EnvironmentObject var persistence: Persistence

    @FetchRequest<SaveStateObject>(sortDescriptors: [])
    var keepPlaying: FetchedResults<SaveStateObject>

    @State private var renameSaveStateTarget: SaveStateObject?
    @State private var deleteSaveStateTarget: SaveStateObject?

    init() {
        let fetchRequest = SaveStateObject.fetchRequest()
        fetchRequest.fetchLimit = 10
        fetchRequest.sortDescriptors = [.init(keyPath: \SaveStateObject.date, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "isAuto == true")
        _keepPlaying = FetchRequest(fetchRequest: fetchRequest)
    }

    var body: some View {
        if !keepPlaying.isEmpty {
            Section {
                VStack(alignment: .leading) {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 16.0) {
                            ForEach(keepPlaying) { saveState in
                                SaveStateItem(
                                    saveState,
                                    title: .game,
                                    formatter: self.saveStateDateFormatter,
                                    renameTarget: $renameSaveStateTarget,
                                    deleteTarget: $deleteSaveStateTarget,
                                    action: self.saveStateSelected
                                )
                                .frame(height: 226.0)
                            }
                        }
                        .padding([.horizontal, .bottom])
                        .modify {
                            if #available(iOS 17.0, macOS 14.0, *) {
                                $0.scrollTargetLayout()
                            } else {
                                $0
                            }
                        }
                    }
                    .modify {
                        if #available(iOS 17.0, macOS 14.0, *) {
                            $0.scrollTargetBehavior(.viewAligned)
                        } else {
                            $0
                        }
                    }
                }
            } header: {
                Text("KEEP_PLAYING")
                    .sectionHeaderStyle()
                    .padding([.horizontal, .top])
            }
            .renameItem("RENAME_SAVE_STATE", item: $renameSaveStateTarget)
            .deleteItem("DELETE_SAVE_STATE", item: $deleteSaveStateTarget) { saveState in
                Text("DELETE_SAVE_STATE_MESSAGE \(saveState.name ?? NSLocalizedString("SAVE_STATE_UNNAMED", comment: ""))")
            }
        }
    }

    func saveStateSelected(_ saveState: SaveStateObject) {
        Task { @MainActor in
            do {
                try await gamePlayback.play(state: saveState, persistence: persistence)
            } catch {
                print(error)
            }
        }
    }
}
