import CoreData

extension Persistence {
    @MainActor
    func obtainObject<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> T {
        request.fetchLimit = 1
        let results = try! mainContext.fetch(request)
        return results.first!
    }
}
