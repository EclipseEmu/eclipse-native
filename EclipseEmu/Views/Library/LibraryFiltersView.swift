import OSLog
import SwiftUI
import EclipseKit

final class LibraryFiltersViewModel: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var systems: Set<GameSystem> = Set(GameSystem.concreteCases)
    @Published var tags: Set<Tag> = []

    var areSystemsFiltered: Bool {
        systems.count != GameSystem.concreteCases.count
    }

    func insertPredicates(_ array: inout [NSPredicate]) {
        array.append(
            NSCompoundPredicate(orPredicateWithSubpredicates: systems.map {
                NSPredicate(format: "rawSystem = %d", $0.rawValue)
            })
        )

        for tag in tags {
            array.append(NSPredicate(format: "tags CONTAINS %@", tag))
        }
    }
}

private extension Binding where Value == Bool {
    @MainActor
    init(_ value: Tag, in viewModel: LibraryFiltersViewModel) {
        self = .init(get: {
            viewModel.tags.contains(value)
        }, set: { newValue in
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.tags.toggle(value, if: newValue)
            }
        })
    }

    @MainActor
    init(_ value: GameSystem, in viewModel: LibraryFiltersViewModel) {
        self = .init(get: {
            viewModel.systems.contains(value)
        }, set: { newValue in
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.systems.toggle(value, if: newValue)
            }
        })
    }
}

struct LibraryFiltersView: View {
    @Environment(\.dismiss) var dismiss: DismissAction

    @ObservedObject var viewModel: LibraryFiltersViewModel

    @FetchRequest<Tag>(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    private var tags: FetchedResults<Tag>

    var body: some View {
        Form {
            Section {
                ForEach(GameSystem.concreteCases, id: \.rawValue) { system in
                    Toggle(isOn: .init(system, in: viewModel)) {
                        Text(system.string)
                            .foregroundStyle(Color.primary)
                    }
                    .toggleStyleCheckbox()
                }
            } header: {
                Text("System")
            }

            Section {
                ForEach(tags) { tag in
                    Toggle(isOn: .init(tag, in: viewModel)) {
                        Label {
                            Text(tag.name ?? "Tag")
                                .foregroundStyle(Color.primary)
                        } icon: {
                            Image(systemName: "tag")
                        }
                    }
                    .toggleStyleCheckbox()
                }
            } header: {
                Text("Tags")
            }
            .emptyState(tags.isEmpty) {
                EmptyView()
            }
        }
        .navigationTitle("Filters")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    @Previewable @StateObject var viewModel = LibraryFiltersViewModel()

    NavigationStack {
        LibraryFiltersView(viewModel: viewModel)
    }
}

