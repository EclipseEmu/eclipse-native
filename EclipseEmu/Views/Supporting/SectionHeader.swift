import SwiftUI

struct SectionHeader<AccessoryContent: View>: View {
    var title: String
    var accessory: () -> AccessoryContent
    
    init(_ title: String, accessory: @escaping () -> AccessoryContent = { EmptyView() }) {
        self.title = title
        self.accessory = accessory
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Spacer()
            self.accessory()
        }
    }
}

#Preview {
    SectionHeader("Keep Playing")
}
