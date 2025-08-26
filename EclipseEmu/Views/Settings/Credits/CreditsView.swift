import SwiftUI

struct CreditsView: View {
    @EnvironmentObject var coreRegistry: CoreRegistry

    var body: some View {
        Form {
            Section("DEVELOPERS") {
                LinkItemView(to: URL(string: "https://magnetar.dev")!) {
                    VStack(alignment: .leading) {
                        Text(verbatim: "Magnetar")
                        Text("DEVELOPER_MAGNETAR_ROLE")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
				ForEach(Core.allCases) { core in
					let coreInfo = core.type
					LinkItemView(to: coreInfo.sourceCodeRepository) {
                        VStack(alignment: .leading) {
                            Text(coreInfo.name)
                            Text(coreInfo.developer)
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

            Section("OPEN_SOURCE_LICENSES") {
                ForEach(openSourceLibraryLicenses) { license in
                    NavigationLink(verbatim: license.name, to: .license(license))
                }
            }
        }
        .navigationTitle("CREDITS")
        .formStyle(.grouped)
    }
}

#Preview {
    CreditsView()
        .environmentObject(CoreRegistry())
}
