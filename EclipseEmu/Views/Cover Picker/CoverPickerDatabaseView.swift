import SwiftUI
import Combine
import EclipseKit

private enum SearchState {
    case loading
    case noQuery
    case results([OpenVGDBItem])
    case failure(OpenVGDBError)
}

private final class CoverPickerDatabaseViewModel: ObservableObject {
    @Published var query: String

    init(query: String) {
        self.query = query
    }
}

struct CoverPickerDatabaseView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @EnvironmentObject var persistence: Persistence

    @ObservedObject private var viewModel: CoverPickerDatabaseViewModel
    @State private var state: SearchState  = .loading
    @State private var searchTask: Task<Void, Never>?
    @State private var db: OpenVGDB?

    @ObservedObject private var game: GameObject
    let system: System

    init(game: GameObject) {
        self.game = game
        self.system = game.system
        let query = game.name?.normalize(with: .alphanumerics.union(.whitespaces)) ?? ""
        self.viewModel = CoverPickerDatabaseViewModel(query: query)
    }

    @ViewBuilder
    var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case .failure(let failure):
            ContentUnavailableMessage.error(error: failure)
        case .noQuery:
            ContentUnavailableMessage {
                Label("COVER_ART_SEARCH_FOR_GAMES", systemImage: "magnifyingglass")
            }
        case .results(let results):
            if results.isEmpty {
                ContentUnavailableMessage.search(text: viewModel.query)
            } else {
                List(results) { result in
                    HStack(alignment: .center, spacing: 12.0) {
                        AsyncImage(url: result.cover) { image in
                            image
                                .resizable()
                                .clipShape(RoundedRectangle(cornerRadius: 2.0))
                                .scaledToFit()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8.0)
                                .foregroundStyle(.secondary)
                        }
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: 52.0, height: 52.0)

                        VStack(alignment: .leading) {
                            Text(result.name)
                                .lineLimit(1)
                            Text(result.region)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("USE") { setCoverArt(result) }
                            .textCase(.uppercase)
                            .controlSize(.small)
                            .fontWeight(.semibold)
                            .buttonStyle(.bordered)
#if !os(macOS)
                            .buttonBorderShape(.capsule)
#endif
                    }
                }
            }
        }
    }

    var body: some View {
        content
            .navigationTitle("COVER_ART")
        #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .searchable(text: $viewModel.query)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton("CANCEL", action: dismiss.callAsFunction)
                }
            }
            .onReceive(viewModel.$query.debounce(for: .milliseconds(250), scheduler: RunLoop.main)) { query in
                self.performSearch(for: query)
            }
    }

    func setCoverArt(_ item: OpenVGDBItem) {
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

    func performSearch(for query: String) {
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

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        NavigationStack {
            CoverPickerDatabaseView(game: game)
        }
    }
}
