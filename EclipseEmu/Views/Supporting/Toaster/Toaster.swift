import SwiftUI

// FIXME: Handle multiple toasts.
// FIXME: Toasts can have an associated action.
// FIXME: Enable switching between states:
//        - Pending: the task is in progress, i.e. games are being added.
//        - Failure: the task that doesn't demand blocking-attention failed, i.e. some games failed to add.
//        - Success: the task succeeded, i.e. adding all games succeeded.

@MainActor
final class Toaster: ObservableObject {
    @Published private(set) var toast: Toast?
    private var toastTask: Task<Void, any Error>?

    func push(_ toast: Toast) {
        toastTask?.cancel()
        toastTask = Task {
            withAnimation(.spring) {
                self.toast = toast
            }
            
            try await Task.sleep(for: .seconds(3))
            withAnimation {
                self.toast = nil
            }
        }
    }
    
    func dismissToast() {
        withAnimation {
            toast = nil
        }
    }
}
