import Foundation
import EclipseKit

extension NotificationCenter {
    @unsafe
    @inlinable
    func objects<Object>(for name: Notification.Name, as: Object.Type) -> AsyncCompactMapSequence<NotificationCenter.Notifications, UnsafeCopyableSend<Object>> {
        return self.notifications(named: name).compactMap { unsafe ($0.object as? Object).map(UnsafeCopyableSend.init) }
    }
}

extension NotificationCenter.Notifications {
    @unsafe
    @inlinable
    func object<Object>(as: Object.Type) -> AsyncCompactMapSequence<NotificationCenter.Notifications, UnsafeCopyableSend<Object>> {
        return self.compactMap { unsafe ($0.object as? Object).map(UnsafeCopyableSend.init) }
    }
}
