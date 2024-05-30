import SwiftUI
import EclipseKit

final class BoxartPickerViewModel: ObservableObject {
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
            await MainActor.run {
                self.state = .success(openvgdb)
            }
        } catch let error as OpenVGDB.Failure {
            await MainActor.run {
                self.state = .failure(error)
            }
        } catch {
            await MainActor.run {
                self.state = .failure(.unknown)
            }
        }
    }

    @MainActor
    func disappear() {
        self.state = .pending
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

fileprivate struct BoxartPickerItemView: View {
    let entry: OpenVGDB.Item
    @Binding var selection: OpenVGDB.Item?

    var body: some View {
        Button {
            self.selection = entry
        } label: {
            HStack {
                AsyncImage(url: entry.boxart) { imagePhase in
                    switch imagePhase {
                    case .success(let image):
                        image
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 8.0))
                            .aspectRatio(1.0, contentMode: .fit)
                    case .failure(_):
                        Image(systemName: "exclamationmark.triangle")
                    case .empty:
                        ProgressView()
                    @unknown default:
                        Image(systemName: "exclamationmark.triangle")
                    }
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading) {
                    Text(verbatim: entry.name)
                        .lineLimit(1)
                    Text(verbatim: entry.region)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .stroke(lineWidth: 1.5)
                    .foregroundStyle(.secondary)
                    .scaleEffect(0.9)
                    .overlay {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                            .imageScale(.small)
                            .padding()
                            .background(.tint)
                            .opacity(Double(selection?.id == entry.id))
                    }
                    .clipShape(Circle())
                    .frame(width: 24, height: 24)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct BoxartPicker: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: BoxartPickerViewModel
    @State var selection: OpenVGDB.Item?
    let initialQuery: String
    let finished: (OpenVGDB.Item) -> Void

    init(system: GameSystem, initialQuery: String = "", finished: @escaping (OpenVGDB.Item) -> Void) {
        self._viewModel = StateObject(wrappedValue: BoxartPickerViewModel(system: system))
        self.initialQuery = initialQuery
        self.finished = finished
    }

    var body: some View {
        CompatNavigationStack {
            Group {
                switch viewModel.searchState {
                case .noQuery:
                    EmptyView()
                case .pending:
                    ProgressView()
                case .empty(let query):
                    ContentUnavailableMessage<EmptyView, EmptyView, EmptyView>.search(text: query)
                case .failure(let error):
                    ContentUnavailableMessage {
                        Label("Failed to Load Boxarts", systemImage: "exclamationmark.octagon.fill")
                    } description: {
                        Text("\(error.localizedDescription)")
                    }
                case .success(let entries):
                    List {
                        Section {
                            ForEach(entries) { entry in
                                BoxartPickerItemView(entry: entry, selection: $selection)
                            }
                        } footer: {
                            Text("Eclipse is not associated with any of these game's developers, publishers, or other parties in anyway. This data is publically available at [OpenVGDB's GitHub](https://github.com/openvgdb/openvgdb).")
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                        if let selection {
                            self.finished(selection)
                        }
                    }.disabled(self.selection == nil)
                }
            }
            .navigationTitle("Boxart Picker")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
}

#Preview("View") {
    BoxartPicker(system: .gba) { _ in }
    #if os(macOS)
        .frame(minWidth: 400, minHeight: 400)
    #endif
}

#Preview("Item") {
    struct BoxartPickerItemPreviewView: View {
        @State var selection: OpenVGDB.Item?

        var body: some View {
            List {
                BoxartPickerItemView(entry: .init(name: "Hello, world", system: .gbc, region: "USA", boxart: nil), selection: $selection)
                BoxartPickerItemView(entry: .init(name: "Hello, world", system: .gbc, region: "USA", boxart: nil), selection: $selection)
                BoxartPickerItemView(entry: .init(name: "Hello, world", system: .gbc, region: "USA", boxart: nil), selection: $selection)
                BoxartPickerItemView(entry: .init(name: "Hello, world", system: .gbc, region: "USA", boxart: nil), selection: $selection)
            }
        }
    }

    return BoxartPickerItemPreviewView()
}
