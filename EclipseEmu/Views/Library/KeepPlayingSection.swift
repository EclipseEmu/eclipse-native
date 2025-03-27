import SwiftUI
import CoreData

struct KeepPlayingSection: View {
    let saveStateDateFormatter = RelativeDateTimeFormatter()

    @EnvironmentObject var gamePlayback: GamePlayback
    @EnvironmentObject var persistence: Persistence

    @FetchRequest<SaveState>(sortDescriptors: [])
    var keepPlaying: FetchedResults<SaveState>

    init() {
        let fetchRequest = SaveState.fetchRequest()
        fetchRequest.fetchLimit = 10
        fetchRequest.sortDescriptors = [.init(keyPath: \SaveState.date, ascending: false)]
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
                                SaveStateItem2(
                                    saveState,
                                    title: .game,
                                    formatter: self.saveStateDateFormatter,
                                    action: self.saveStateSelected
                                )
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
                Text("Keep Playing")
                    .sectionHeaderStyle()
                    .padding([.horizontal, .top])
            }
        }
    }

    func saveStateSelected(_ saveState: SaveState) {
        Task { @MainActor in
            do {
                try await gamePlayback.play(state: saveState, persistence: persistence)
            } catch {
                print(error)
            }
        }
    }
}
