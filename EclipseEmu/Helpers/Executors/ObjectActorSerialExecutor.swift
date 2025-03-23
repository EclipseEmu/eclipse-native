import Foundation
import CoreData

final class ObjectActorSerialExecutor: @unchecked Sendable, SerialExecutor {
    private let objectContext: NSManagedObjectContext

    init(objectContext: NSManagedObjectContext) {
        self.objectContext = objectContext
    }

    func enqueue(_ job: UnownedJob) {
        self.objectContext.perform {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
