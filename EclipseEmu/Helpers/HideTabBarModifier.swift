import SwiftUI

#if canImport(UIKit)
fileprivate func findView(root: UIView, where predicate: @escaping (UIView) -> Bool) -> UIView? {
    guard !predicate(root) else { return root }

    for subview in root.subviews {
        if let resp = findView(root: subview, where: predicate) {
            return resp
        }
    }

    return nil
}

extension View {
    func tabBarHidden() -> some View {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 as? UIWindowScene != nil }) as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow }),
            let tabbar = findView(root: window, where: { $0 as? UITabBar != nil })
        else {
            return AnyView(self)
        }

        return AnyView(self
            .onAppear {
                tabbar.isHidden = true
            }
            .onDisappear {
                tabbar.isHidden = false
            })
    }
}
#endif
