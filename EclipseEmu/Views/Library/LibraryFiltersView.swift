import OSLog
import SwiftUI
import EclipseKit

struct LibraryFiltersView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    @FetchRequest<TagObject>(sortDescriptors: [NSSortDescriptor(keyPath: \TagObject.name, ascending: true)])
    private var allTags: FetchedResults<TagObject>

    @Binding var systems: Set<System>
    @Binding var tags: Set<TagObject>

    var body: some View {
        Form {
            Section {
                ForEach(System.concreteCases, id: \.rawValue) { system in
                    Toggle(isOn: .init(get: {
                        systems.contains(system)
                    }, set: { newValue in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            systems.toggle(system, if: newValue)
                        }
                    })) {
                        Text(system.string)
                            .foregroundStyle(Color.primary)
                    }
                }
            } header: {
                Text("SYSTEM")
            }

            Section {
                ForEach(allTags) { tag in
                    Toggle(isOn: .init(get: {
                        tags.contains(tag)
                    }, set: { newValue in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            tags.toggle(tag, if: newValue)
                        }
                    })) {
                        Label {
                            Text(verbatim: tag.name, fallback: "TAG")
                                .foregroundStyle(Color.primary)
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
#Preview(traits: .modifier(PreviewStorage())) {
    @Previewable @State var systems: Set<System> = []
    @Previewable @State var tags: Set<TagObject> = []

    NavigationStack {
        LibraryFiltersView(systems: $systems, tags: $tags)
    }
}

