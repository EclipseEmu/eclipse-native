import SwiftUI
import CoreData

protocol UnmanagedObjectProtocol: Sendable {
    var objectID: NSManagedObjectID { get }
}

protocol IntoUnmanagedObject: NSManagedObject {
    associatedtype UnmanagedObject: UnmanagedObjectProtocol
    func intoUnmanagedObject() -> UnmanagedObject
}

@MainActor
final class ObjectsRequest<Result: IntoUnmanagedObject>: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    private let controller: NSFetchedResultsController<Result>

    @Published var items: [Result.UnmanagedObject] = []

    init(
        context: NSManagedObjectContext,
        filter: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]
    ) {
        let request = NSFetchRequest<Result>(entityName: Result.entity().name ?? "<not set>")
        request.predicate = filter
        request.sortDescriptors = sortDescriptors.isEmpty ? nil : sortDescriptors
        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init()
        controller.delegate = self
        refresh()
    }

    private func refresh() {
        do {
            try controller.performFetch()
        } catch {
            print(error)
        }
    }

    private func update() {
        items = if let objects = controller.fetchedObjects {
            objects.map { $0.intoUnmanagedObject() }
        } else {
            []
        }
    }

    var predicate: NSPredicate? {
        get {
            controller.fetchRequest.predicate
        }
        set {
            controller.fetchRequest.predicate = newValue
            refresh()
        }
    }

    var sortDescriptors: [NSSortDescriptor] {
        get {
            controller.fetchRequest.sortDescriptors ?? []
        }
        set {
            controller.fetchRequest.sortDescriptors = newValue.isEmpty ? nil : newValue
            refresh()
        }
    }

    nonisolated func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.objectWillChange.send()
    }

    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        MainActor.assumeIsolated {
            update()
        }
    }
}
