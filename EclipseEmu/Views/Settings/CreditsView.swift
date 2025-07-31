import SwiftUI

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
				ForEach(Core.allCases) { core in
					let coreInfo = core.type
					Link(destination: coreInfo.sourceCodeRepository) {
						HStack {
							VStack(alignment: .leading) {
								Text(coreInfo.name)
									.foregroundStyle(Color.primary)
								Text(coreInfo.developer)
									.font(.caption)
									.foregroundStyle(Color.secondary)
							}
							Spacer()
							Image(systemName: "arrow.up.right.square")
								.foregroundStyle(Color.secondary)
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
        .environmentObject(CoreRegistry())
}
