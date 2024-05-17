import SwiftUI

struct BoxartView: View {
    var body: some View {
        Rectangle()
            .aspectRatio(1.0, contentMode: .fit)
    }
}

#Preview {
    BoxartView()
        .padding()
}
