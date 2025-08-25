import OSLog
import SwiftUI
import EclipseKit

struct LibraryFiltersView: View {
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    @FetchRequest<TagObject>(sortDescriptors: [NSSortDescriptor(keyPath: \TagObject.name, ascending: true)])
    private var allTags: FetchedResults<TagObject>

    var body: some View {
        Form {
            Section {
                ForEach(System.concreteCases, id: \.rawValue) { system in
                    Toggle(isOn: .init(get: {
                        viewModel.filteredSystems.contains(system)
                    }, set: { newValue in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.filteredSystems.toggle(system, if: newValue)
                        }
                    })) {
                        Text(system.string).foregroundStyle(Color.primary)
                    }
                }
            } header: {
                Text("SYSTEM")
            }

            Section {
                ForEach(allTags) { tag in
                    Toggle(isOn: .init(get: {
                        viewModel.filteredTags.contains(tag)
                    }, set: { newValue in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.filteredTags.toggle(tag, if: newValue)
                        }
                    })) {
                        Label {
                            Text(verbatim: tag.name, fallback: "TAG").foregroundStyle(Color.primary)
                        } icon: {
                            Image(systemName: "tag")
                        }
                    }
                    .listItemTint(tag.color.color)
                }
            } header: {
                Text("TAGS")
            }
            .emptyState(allTags.isEmpty) {
                EmptyView()
            }
        }
        .formStyle(.grouped)
        .toggleStyleCheckbox()
        .navigationTitle("FILTERS")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("DONE", action: dismiss.callAsFunction)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    @Previewable @StateObject var viewModel: LibraryViewModel = .init()

    NavigationStack {
        LibraryFiltersView(viewModel: viewModel)
    }
}
