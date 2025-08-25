import SwiftUI
import CoreData

struct KeepPlayingSection: View {
    static let fetchRequest: NSFetchRequest = {
        let fetchRequest = SaveStateObject.fetchRequest()
        fetchRequest.fetchLimit = 10
        fetchRequest.sortDescriptors = [.init(keyPath: \SaveStateObject.date, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "isAuto == true")
        return fetchRequest
    }()
    
    @ObservedObject var viewModel: LibraryViewModel
    @FetchRequest<SaveStateObject>(fetchRequest: Self.fetchRequest)
    private var keepPlaying: FetchedResults<SaveStateObject>

    var body: some View {
        if !keepPlaying.isEmpty {
            Section {
                VStack(alignment: .leading) {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 16.0) {
                            ForEach(keepPlaying) { saveState in
                                KeepPlayingItemView(saveState: saveState, viewModel: viewModel)
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
        }
    }
}

private struct KeepPlayingItemView: View {
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var playback: GamePlayback
    @EnvironmentObject private var coreRegistry: CoreRegistry

    @ObservedObject var saveState: SaveStateObject
    @ObservedObject var viewModel: LibraryViewModel
    @State private var error: GameViewError?

    var body: some View {
        SaveStateItem(saveState, title: .game, action: self.action)
            .frame(height: 226.0)
            .modify {
                if let game = saveState.game {
                    $0.gameErrorHandler(game: game, error: $error, fileImportRequest: $viewModel.fileImportRequest)
                } else {
                    $0
                }
            }
    }

    private func action(_ saveState: SaveStateObject) {
        Task { @MainActor in
            do {
                try await playback.play(state: saveState, persistence: persistence, coreRegistry: coreRegistry)
            } catch {
                print(error)
                self.error = .playbackError(error as! GamePlaybackError)
            }
        }
    }
}
