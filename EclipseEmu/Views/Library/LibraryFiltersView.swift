import OSLog
import SwiftUI
import EclipseKit

final class LibraryFiltersViewModel: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var system: GameSystem = .unknown
    @Published var tags: Set<Tag> = []

    func insertPredicates(_ array: inout [NSPredicate]) {
        if system != .unknown {
            array.append(NSPredicate(format: "rawSystem = %d", system.rawValue))
        }

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
                if newValue {
                    viewModel.tags.insert(value)
                } else {
                    viewModel.tags.remove(value)
                }
            }
        })
    }
}

private struct MultiSelectToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer()
                // FIXME: Checkmark doesn't line up with the system one for the normal Picker.
                Image(systemName: "checkmark")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.tint)
                    .opacity(configuration.isOn ? 1.0 : 0.0)
                    .scaleEffect(configuration.isOn ? 1.0 : 0.9)
            }
        }
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
                Picker("System", selection: $viewModel.system) {
                    ForEach(GameSystem.allCases, id: \.rawValue) { system in
                        Text(system == .unknown ? "Any" : system.string).tag(system)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
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
                    .toggleStyle(MultiSelectToggleStyle())
                }
            } header: {
                Text("Tags")
            }
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.inline)
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

