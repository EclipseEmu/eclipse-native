import SwiftUI

struct SectionHeader: View {
    var title: String
    
    var body: some View {
        Text(title)
            .font(.title3)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .fontWeight(.semibold)
    }
}

#Preview {
    SectionHeader(title: "Keep Playing")
}
