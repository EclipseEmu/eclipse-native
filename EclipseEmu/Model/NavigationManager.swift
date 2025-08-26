import SwiftUI

final class NavigationManager: ObservableObject {
    @Published var path: NavigationPath = NavigationPath()
}
