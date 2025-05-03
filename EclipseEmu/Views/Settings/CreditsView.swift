import SwiftUI
import mGBAEclipseCore

struct CreditsView: View {
    @EnvironmentObject var coreRegistry: CoreRegistry

    var body: some View {
        Form {
            Section {
                Link(destination: URL(string: "https://magnetar.dev")!) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(verbatim: "Magnetar")
                                .foregroundStyle(Color.primary)
                            Text("DEVELOPER_MAGNETAR_ROLE")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(Color.secondary)
                    }
                }
            } header: {
                Text("DEVELOPERS")
            }

            Section {
                ForEach(coreRegistry.cores) { core in
                    if let url = core.sourceCodeUrl {
                        Link(destination: url) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(core.name)
                                        .foregroundStyle(Color.primary)
                                    Text(core.developer)
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text(core.name)
                            Text(core.developer)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("CORES")
            } footer: {
                Text("ECLIPSE_CORE_DEVELOPERS_MESSAGE")
            }

            Section {
                NavigationLink(to: .licenses) {
                    Text("OPEN_SOURCE_LICENSES")
                }
            }
        }
        .navigationTitle("CREDITS")
        .formStyle(.grouped)
    }
}

#Preview {
    CreditsView()
        .environmentObject(CoreRegistry(cores: [mGBACoreInfo]))
}
