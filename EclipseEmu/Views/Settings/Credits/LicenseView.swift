import SwiftUI

struct LicenseView: View {
    let license: LicenseItem

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(verbatim: license.content)
                .font(.caption2.monospaced())
                .padding()
                .fixedSize(horizontal: true, vertical: true)
        }
        .navigationTitle(license.name)
    }
}

#Preview {
    NavigationStack {
        LicenseView(license: openSourceLibraryLicenses[0])
    }
}
