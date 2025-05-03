import SwiftUI
import EclipseKit

struct CoreSettingsView: View {
    let core: CoreInfo

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("CORE_NAME")
                    Spacer()
                    Text(core.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("CORE_DEVELOPER")
                    Spacer()
                    Text(core.developer)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("CORE_VERSION")
                    Spacer()
                    Text(core.version)
                        .foregroundStyle(.secondary)
                }
                if let sourceCodeUrl = core.sourceCodeUrl {
                    Link(destination: sourceCodeUrl) {
                        Label("SOURCE_CODE", systemImage: "folder")
                    }
                }
            } header: {
                Text("INFORMATION")
            }

            Section {
                ForEach(core.settings.items) { setting in
                    switch setting.kind {
                    case .bool(let bool):
                        Toggle(isOn: .constant(bool.defaultValue)) {
                            Text(setting.displayName)
                        }
                    case .file(let file):
                        HStack {
                            Text(setting.displayName)
                            Text(file.displayName).foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                print(file.sha1)
                            } label: {
                                Text("SELECT_FILE")
                            }
                        }
                    case .unknown:
                        EmptyView()
                    }
                }
            } header: {
                Text("SETTINGS")
            }
            .emptyState(core.settings.items.isEmpty) { EmptyView() }
        }
        .formStyle(.grouped)
        .navigationTitle(core.name)
    }
}
