import Foundation
import EclipseKit

enum ControllerProfileVersion: Int16, RawRepresentable {
    case v1 = 1
}

final class ControllerProfile: ObservableObject, Identifiable, Hashable {
    var name: String
    var rawSystem: Int16
    var system: GameSystem
    var rawVersion: Int16
    var version: ControllerProfileVersion?
    var data: Data

    init(
        name: String,
        rawSystem: Int16,
        system: GameSystem,
        rawVersion: Int16,
        version: ControllerProfileVersion?,
        data: Data
    ) {
        self.name = name
        self.rawSystem = rawSystem
        self.system = system
        self.rawVersion = rawVersion
        self.version = version
        self.data = data
    }

    static func == (lhs: ControllerProfile, rhs: ControllerProfile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        self.id.hash(into: &hasher)
    }
}
