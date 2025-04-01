import SwiftUI
import EclipseKit

struct CoreSettingsView: View {
    let core: CoreInfo

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(core.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Developer")
                    Spacer()
                    Text(core.developer)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text(core.version)
                        .foregroundStyle(.secondary)
                }
                if let sourceCodeUrl = core.sourceCodeUrl {
                    Link(destination: sourceCodeUrl) {
                        Label("Source Code", systemImage: "folder")
                    }
                }
            } header: {
                Text("Info")
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
                                Text("Select File")
                            }
                        }
                    case .unknown:
                        EmptyView()
                    }
                }
            } header: {
                Text("Settings")
            }
            .emptyState(core.settings.items.isEmpty) { EmptyView() }
        }
        .navigationTitle(core.name)
    }
}
