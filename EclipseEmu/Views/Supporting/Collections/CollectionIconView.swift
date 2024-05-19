import SwiftUI

struct CollectionIconView: View {
    let icon: GameCollection.Icon
    
    var body: some View {
        switch self.icon {
        case .unknown:
            Text(Image(systemName: "exclamationmark.triangle"))
                .fontWeight(.semibold)
        case .symbol(let systemName):
            Text(Image(systemName: systemName))
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    CollectionIconView(icon: .symbol("list.bullet"))
}
