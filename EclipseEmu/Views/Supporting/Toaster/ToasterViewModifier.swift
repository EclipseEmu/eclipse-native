import SwiftUI

struct ToasterViewModifier: ViewModifier {
    @ObservedObject var toaster: Toaster
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let toast = toaster.toast {
                    HStack(spacing: 16.0) {
                        Label {
                            Text(toast.message).font(.callout).lineLimit(1)
                        } icon: {
                            toast.image
                        }
                        .padding(.leading, 4.0)
                        Spacer()
                        Button("DISMISS", systemImage: "xmark", role: .destructive, action: toaster.dismissToast)
                            .labelStyle(.iconOnly)
                            .modify {
                                if #available(iOS 26.0, macOS 26.0, *) {
                                    $0.buttonStyle(.glass).buttonBorderShape(.circle)
                                } else {
                                    $0.buttonStyle(.bordered).tint(Color.primary)
                                }
                            }
                    }
                    .frame(minWidth: 0, maxWidth: 256)
                    .padding(.all, 12.0)
                    .modify {
                        if #available(iOS 26.0, macOS 26.0, *) {
                            $0.glassEffect(.regular.interactive(), in: .capsule)
                        } else {
                            $0.background(Material.ultraThick).clipShape(RoundedRectangle(cornerRadius: 99.0))
                        }
                    }
                    .padding(.bottom)
                }
            }
    }
}

extension View {
    func presentingToasts(from toaster: Toaster) -> some View {
        self.modifier(ToasterViewModifier(toaster: toaster))
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview {
    @Previewable @StateObject var toaster = Toaster()
    
    NavigationStack {
        ScrollView {
            LazyVStack {
                ForEach(0..<100) { i in
                    let color: Color = if i % 5 == 0 {
                        Color.red
                    } else if i % 3 == 0 {
                        Color.green
                    } else {
                        Color.blue
                    }
                    
                    Text(verbatim: "Some text")
                        .padding()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(color)
                }
            }
        }
        .toolbar {
            Button {
                toaster.push(.init("DISMISS", systemImage: "gear"))
            } label: {
                Text(verbatim: "Show Toast")
            }
        }
        .presentingToasts(from: toaster)
    }
}
