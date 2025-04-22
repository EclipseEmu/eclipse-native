import SwiftUI

private struct LicenseView: View {
    let license: LicenseItem
    @State private var isExpanded = true

    init(license: LicenseItem) {
        self.license = license
    }

    var body: some View {
        Section {
            Text(verbatim: license.content)
                .font(.caption2)
                .listRowSeparator(.hidden)
        } header: {
            Text(verbatim: license.name)
        }
        .headerProminence(.increased)
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            ForEach(openSourceLibraryLicenses) { license in
                LicenseView(license: license)
            }
        }
        .listStyle(.plain)
        .navigationTitle("LICENSES")
    }
}

#Preview {
    NavigationStack {
        LicensesView()
    }
}
