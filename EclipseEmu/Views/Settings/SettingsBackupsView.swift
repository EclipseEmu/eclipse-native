import SwiftUI

struct SettingsBackupsView: View {
    var body: some View {
        List {
        }
            .navigationTitle("Backups")
            .toolbar {
                #if os(iOS)
                ToolbarItem {
                    EditButton()
                }
                #endif
                ToolbarItem {
                    Button {} label: {
                        Label("Create Backup", systemImage: "plus")
                    }
                }
            }
    }
}

#Preview {
    SettingsBackupsView()
}
