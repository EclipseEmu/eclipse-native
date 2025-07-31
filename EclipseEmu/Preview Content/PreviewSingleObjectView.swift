import SwiftUI
import CoreData

struct PreviewSingleObjectView<T: NSManagedObject, Content: View>: View {
    @EnvironmentObject private var persistence: Persistence

    let fetchRequest: NSFetchRequest<T>
    let content: (T, Persistence) -> Content
	@State var object: T?

    init(_ fetchRequest: NSFetchRequest<T>, @ViewBuilder content: @escaping (T, Persistence) -> Content) {
        self.fetchRequest = fetchRequest
        self.content = content
    }

	@ViewBuilder
	var obtainedContent: some View {
		if let object {
			content(object, persistence)
		} else {
			ProgressView()
		}
	}

    var body: some View {
		obtainedContent.onAppear {
			fetchRequest.fetchLimit = 1
			let results = try! persistence.mainContext.fetch(fetchRequest)
			object = results.first!
		}
    }
}
