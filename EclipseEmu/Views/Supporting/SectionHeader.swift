import SwiftUI

struct SectionHeader: View {
    var title: String
    
    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SectionHeader(title: "Keep Playing")
}
