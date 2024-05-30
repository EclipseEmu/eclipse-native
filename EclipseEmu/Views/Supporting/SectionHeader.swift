import SwiftUI

struct SectionHeader: View {
    var title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SectionHeader("Keep Playing")
}
