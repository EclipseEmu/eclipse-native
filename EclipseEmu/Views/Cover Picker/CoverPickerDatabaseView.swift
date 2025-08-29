import SwiftUI
import Combine
import EclipseKit

private enum SearchState {
    case loading
    case noQuery
    case results([OpenVGDBItem])
    case failure(OpenVGDBError)
}

@MainActor
private final class CoverPickerDatabaseViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var state: SearchState  = .loading
    @Published private var searchTask: Task<Void, Never>?
    @Published private var db: OpenVGDB?
    
    func search(for query: String, system: System) {
        searchTask?.cancel()
        if query.isEmpty {
            self.state = .noQuery
            self.searchTask = nil
            return
        }

        searchTask = Task {
            do {
                if self.db == nil {
                    self.db = try OpenVGDB()
                    await Task.yield()
                }

                let results = try await self.db!.search(query: query, system: system)
                self.state = .results(results)
            } catch {
                self.state = .failure(error as! OpenVGDBError)
            }
        }
    }
}

struct CoverPickerDatabaseView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var persistence: Persistence

    @StateObject private var viewModel: CoverPickerDatabaseViewModel = .init()
    @ObservedObject private var game: GameObject
    private let system: System

    init(game: GameObject) {
        self.game = game
        self.system = game.system
    }
    
    var body: some View {
        content
            .navigationTitle("COVER_ART")
            .searchable(text: $viewModel.query)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton("CANCEL", action: dismiss.callAsFunction)
                }
            }
            .onAppear {
                viewModel.query = game.name?.normalize(with: .alphanumerics.union(.whitespaces)) ?? ""
                viewModel.search(for: viewModel.query, system: game.system)
            }
            .onReceive(viewModel.$query.debounce(for: .milliseconds(250), scheduler: RunLoop.main)) { query in
                viewModel.search(for: query, system: game.system)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .failure(let failure):
            ContentUnavailableMessage.error(error: failure)
        case .noQuery:
            ContentUnavailableMessage("COVER_ART_SEARCH_FOR_GAMES", systemImage: "magnifyingglass")
        case .results(let results) where results.isEmpty:
            ContentUnavailableMessage.search(text: viewModel.query)
        case .results(let results):
            List(results, rowContent: listItem)
        }
    }
    
    @ViewBuilder
    private func listItem(_ item: OpenVGDBItem) -> some View {
        LabeledContent {
            Button("USE") {
                setCoverArt(item)
            }
            .textCase(.uppercase)
            .buttonStyle(.bordered)
            .layoutPriority(1)
        } label: {
            HStack(alignment: .center, spacing: 12.0) {
                RemoteImageView(item.cover, aspectRatio: 1.0, cornerRadius: 4.0)
                    .frame(width: 52.0, height: 52.0)
                
                VStack(alignment: .leading) {
                    Text(item.name).lineLimit(2)
                    Text(item.region)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .labeledContentStyle(.noWrap)
    }
    
    private func setCoverArt(_ item: OpenVGDBItem) {
        guard let cover = item.cover else { return }
        let box = ObjectBox(game)
        Task {
            do {
                try await persistence.objects.replaceCoverArt(game: box, fromRemote: cover)
                dismiss()
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
        FormSheetView {
            CoverPickerDatabaseView(game: game)
        }
    }
}
