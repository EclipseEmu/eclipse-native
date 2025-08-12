import SwiftUI
import GameController

struct ForEachConnectedControllers<ItemContent: View, EmptyContent: View>: View {
    @EnvironmentObject private var connectedControllers: ConnectedControllers
    private let itemContent: (GCController) -> ItemContent
    private let emptyContent: () -> EmptyContent
    
    init(@ViewBuilder content: @escaping (GCController) -> ItemContent, isEmpty: @escaping () -> EmptyContent) {
        self.itemContent = content
        self.emptyContent = isEmpty
    }
    
    var body: some View {
        content
            .onAppear(perform: connectedControllers.start)
            .onDisappear(perform: connectedControllers.stop)
            .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect), perform: connectedControllers.handleNotification)
            .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidDisconnect), perform: connectedControllers.handleNotification)
    }
    
    @ViewBuilder
    var content: some View {
        if connectedControllers.controllers.isEmpty {
            emptyContent()
        } else {
            ForEach(connectedControllers.controllers) { controller in
                itemContent(controller)
            }
        }
    }
}

extension ForEachConnectedControllers where EmptyContent == EmptyView {
    init(@ViewBuilder content: @escaping (GCController) -> ItemContent) {
        self.itemContent = content
        self.emptyContent = { EmptyView() }
    }
}
