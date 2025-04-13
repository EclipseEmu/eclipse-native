import OSLog
import SwiftUI
import EclipseKit

struct LibraryFiltersView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    @FetchRequest<Tag>(sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)])
    private var allTags: FetchedResults<Tag>

    @Binding var systems: Set<GameSystem>
    @Binding var tags: Set<Tag>

    var body: some View {
        Form {
            Section {
                ForEach(GameSystem.concreteCases, id: \.rawValue) { system in
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
                Text("System")
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
                            Text(tag.name ?? "Tag")
                                .foregroundStyle(Color.primary)
                        } icon: {
                            Image(systemName: "tag")
                        }
                    }
                    .listItemTint(tag.color.color)
                }
            } header: {
                Text("Tags")
            }
            .emptyState(allTags.isEmpty) {
                EmptyView()
            }
        }
        .toggleStyleCheckbox()
        .navigationTitle("Filters")
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: dismiss.callAsFunction)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    @Previewable @State var systems: Set<GameSystem> = []
    @Previewable @State var tags: Set<Tag> = []

    NavigationStack {
        LibraryFiltersView(systems: $systems, tags: $tags)
    }
}

