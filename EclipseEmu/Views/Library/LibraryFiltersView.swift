import OSLog
import SwiftUI
import EclipseKit

struct LibraryFiltersView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    @ObservedObject var viewModel: LibraryViewModel
    @FetchRequest<TagObject>(sortDescriptors: [NSSortDescriptor(keyPath: \TagObject.name, ascending: true)])
    private var allTags: FetchedResults<TagObject>

    var body: some View {
        Form {
            Section("SYSTEM") {
                ForEach(System.concreteCases, id: \.rawValue) { system in
                    Toggle(isOn: .isInSet(system, set: $viewModel.filteredSystems)) {
                        Text(system.string).foregroundStyle(Color.primary)
                    }
                }
            }

            Section("TAGS") {
                if !allTags.isEmpty {
                    ForEach(allTags) { tag in
                        Toggle(isOn: .isInSet(tag, set: $viewModel.filteredTags)) {
                            Label {
                                Text(verbatim: tag.name, fallback: "TAG").foregroundStyle(Color.primary)
                            } icon: {
                                Image(systemName: "tag")
                            }
                        }
                        .listItemTint(tag.color.color)
                    }
                } else {
                    EmptyMessage(title: "NO_TAGS", message: "NO_TAGS_MESSAGE")
                }
            }
        }
        .formStyle(.grouped)
        .toggleStyleCheckbox()
        .navigationTitle("FILTERS")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                ConfirmButton("DONE", action: dismiss.callAsFunction)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    @Previewable @StateObject var viewModel: LibraryViewModel = .init()

    FormSheetView {
        LibraryFiltersView(viewModel: viewModel)
    }
}
