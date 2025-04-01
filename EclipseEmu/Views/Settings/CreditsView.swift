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
                            Text("Magnetar")
                                .foregroundStyle(Color.primary)
                            Text("Lead Developer & Designer")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(Color.secondary)
                    }
                }
            } header: {
                Text("Developers")
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
                Text("Cores")
            } footer: {
                Text("Eclipse wouldn't be possible without the core developers' hard work. Please support them however you can.")
            }

            Section {
                NavigationLink(to: .licenses) {
                    Text("Open Source Licenses")
                }
            }
        }
        .navigationTitle("Credits")
        .formStyle(.grouped)
    }
}

#Preview {
    CreditsView()
        .environmentObject(CoreRegistry(cores: [mGBACoreInfo], settings: Settings()))
}
