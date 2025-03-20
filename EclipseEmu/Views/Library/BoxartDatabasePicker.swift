import EclipseKit
import SwiftUI

@MainActor
final class BoxartDatabasePickerViewModel: ObservableObject {
    enum SearchState {
        case noQuery
        case pending
        case empty(String)
        case success([OpenVGDB.Item])
        case failure(OpenVGDB.Failure)
    }

    enum State {
        case pending
        case failure(OpenVGDB.Failure)
        case success(OpenVGDB)
    }

    var system: GameSystem
    @Published var state: State = .pending
    @Published var searchState: SearchState = .noQuery
    @Published var query: String = ""

    init(system: GameSystem) {
        self.system = system
        self.state = state
        self.searchState = searchState
        self.query = query
    }

    func appeared() async {
        guard case .pending = state else { return }
        do {
            let openvgdb = try await OpenVGDB()
            self.state = .success(openvgdb)
        } catch let error as OpenVGDB.Failure {
            self.state = .failure(error)
        } catch {
            self.state = .failure(.unknown)
        }
    }

    @MainActor
    func disappear() {
        state = .pending
    }

    func search(query: String) {
        guard case .success(let openvgdb) = state else { return }

        Task {
            guard !query.isEmpty else {
                await MainActor.run {
                    self.searchState = .noQuery
                }
                return
            }

            await MainActor.run {
                self.searchState = .pending
            }

            do {
                let results = try await openvgdb.search(query: query, system: system)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.searchState = if results.isEmpty {
                        .empty(query)
                    } else {
                        .success(results)
                    }
                }
            } catch {
                let properError = (error as? OpenVGDB.Failure) ?? .unknown
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.searchState = .failure(properError)
                }
            }
        }
    }
}

struct BoxartDatabasePickerItemView: View {
    let entry: OpenVGDB.Item

    var body: some View {
        HStack {
            AsyncImage(url: entry.boxart) { imagePhase in
                switch imagePhase {
                case .success(let image):
                    image
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                case .failure:
                    Image(systemName: "exclamationmark.triangle")
                case .empty:
                    ProgressView()
                @unknown default:
                    Image(systemName: "exclamationmark.triangle")
                }
            }
            .frame(width: 44, height: 44)
            .aspectRatio(1.0, contentMode: .fit)

            VStack(alignment: .leading) {
                Text(verbatim: entry.name)
                    .lineLimit(1)
                Text(verbatim: entry.region)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

struct BoxartDatabasePicker: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: BoxartDatabasePickerViewModel
    let initialQuery: String
    let finished: (OpenVGDB.Item) -> Void

    init(system: GameSystem, initialQuery: String = "", finished: @escaping (OpenVGDB.Item) -> Void) {
        self._viewModel = StateObject(wrappedValue: BoxartDatabasePickerViewModel(system: system))
        self.initialQuery = initialQuery
        self.finished = finished
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.searchState {
                case .noQuery:
                    ContentUnavailableMessage {
                        Label("Search for Box Art", systemImage: "magnifyingglass")
                    } description: {
                        // swiftlint:disable:next line_length
                        Text("Data is pulled from [OpenVGDB](https://github.com/openvgdb/openvgdb). Eclipse is not affiliated with any of these games' developers or publishers in any way.")
                    }
                case .pending:
                    ProgressView()
                case .empty(let query):
                    ContentUnavailableMessage<EmptyView, EmptyView, EmptyView>.search(text: query)
                case .failure(let error):
                    ContentUnavailableMessage {
                        Label("Failed to Load Box Art", systemImage: "exclamationmark.octagon.fill")
                    } description: {
                        Text("\(error.localizedDescription)")
                    }
                case .success(let entries):
                    List {
                        Section {
                            ForEach(entries) { entry in
                                Button {
                                    dismiss()
                                    self.finished(entry)
                                } label: {
                                    BoxartDatabasePickerItemView(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        } footer: {
                            // swiftlint:disable:next line_length
                            Text("Data is pulled from [OpenVGDB](https://github.com/openvgdb/openvgdb). Eclipse is not affiliated with any of these games' developers or publishers in any way.")
                        }
                    }
                }
            }
            .searchable(text: $viewModel.query)
            .onReceive(viewModel.$query.debounce(for: 1, scheduler: RunLoop.main)) { query in
                viewModel.search(query: query)
            }
            .task {
                await viewModel.appeared()
                self.viewModel.query = initialQuery
            }
            .onDisappear {
                self.viewModel.disappear()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Box Art")
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview("View") {
    BoxartDatabasePicker(system: .gba) { _ in }
    #if os(macOS)
        .frame(minWidth: 400, minHeight: 400)
    #endif
}

#Preview("Item") {
    List {
        BoxartDatabasePickerItemView(entry: .init(name: "Hello, world", system: .gbc, region: "USA", boxart: nil))
        BoxartDatabasePickerItemView(entry: .init(name: "Hello, world", system: .gbc, region: "USA", boxart: nil))
        BoxartDatabasePickerItemView(entry: .init(name: "Hello, world", system: .gbc, region: "USA", boxart: nil))
        BoxartDatabasePickerItemView(entry: .init(name: "Hello, world", system: .gbc, region: "USA", boxart: nil))
    }
}
