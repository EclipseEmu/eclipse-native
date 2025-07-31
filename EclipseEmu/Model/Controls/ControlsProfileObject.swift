import EclipseKit
import CoreData

protocol VersionProtocol: RawRepresentable<Int16> {
    static var latest: Self { get }
}

@objc
protocol ControlsConfigRawObject {
    @objc dynamic var name: String? { get set }
    @objc dynamic var data: Data? { get set }
    @objc dynamic var rawVersion: Int16 { get set }
    @objc dynamic var rawSystem: Int16 { get set }
}

protocol ControlsProfileObject: Identifiable, NSManagedObject, ControlsConfigRawObject {
	associatedtype Version: VersionProtocol

	var version: Self.Version? { get set }
	var system: System { get set }
    
    @MainActor
    static func navigationDestination(_ object: Self) -> Destination
}
