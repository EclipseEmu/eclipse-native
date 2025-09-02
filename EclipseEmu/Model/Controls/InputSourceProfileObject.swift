import EclipseKit
import CoreData

protocol InputSourceVersionProtocol: RawRepresentable<Int16> {
    static var latest: Self { get }
}

@objc
protocol InputSourceConfigRawObject {
    @objc dynamic var name: String? { get set }
    @objc dynamic var data: Data? { get set }
    @objc dynamic var rawVersion: Int16 { get set }
    @objc dynamic var rawSystem: Int16 { get set }
}

protocol InputSourceProfileObject: Identifiable, NSManagedObject, InputSourceConfigRawObject {
	associatedtype Version: InputSourceVersionProtocol

	var version: Self.Version? { get set }
	var system: System { get set }
    
    @MainActor
    static func navigationDestination(_ object: Self) -> Destination
}
