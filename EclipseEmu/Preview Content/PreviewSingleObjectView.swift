import SwiftUI
import CoreData

struct PreviewSingleObjectView<T: NSManagedObject, Content: View>: View {
    @EnvironmentObject private var persistence: Persistence

    let fetchRequest: NSFetchRequest<T>
    let content: (T, Persistence) -> Content

    init(_ fetchRequest: NSFetchRequest<T>, @ViewBuilder content: @escaping (T, Persistence) -> Content) {
        self.fetchRequest = fetchRequest
        self.content = content
    }

    var body: some View {
        let object = persistence.obtainObject(fetchRequest)
        return content(object, persistence)
    }
}
