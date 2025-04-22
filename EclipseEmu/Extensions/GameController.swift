import GameController

extension GCController: @retroactive Identifiable {}
extension GCKeyCode: Codable {}

extension GCController {
    var symbol: String {
        switch self.productCategory {
        case GCProductCategoryXboxOne:
            "xbox.logo"
        case GCProductCategoryDualSense, GCProductCategoryDualShock4:
            "playstation.logo"
        default:
            "gamecontroller"
        }
    }

    var batterySymbol: String {
        guard let battery else { return "cable.connector" }
        return switch battery.batteryState {
        case .unknown:        "battery.0percent"
        case .full:           "battery.100percent"
        case .discharging: switch battery.batteryLevel {
            case 0:           "battery.0percent"
            case 0.00...0.25: "battery.25percent"
            case 0.25...0.50: "battery.50percent"
            case 0.50...0.75: "battery.75percent"
            case 0.75...1.00: "battery.100percent"
            default:          "battery.0percent"
            }
        case .charging: switch battery.batteryLevel {
        case 0:           "battery.0percent.bolt"
        case 0.00...0.25: "battery.25percent.bolt"
        case 0.25...0.50: "battery.50percent.bolt"
        case 0.50...0.75: "battery.75percent.bolt"
        case 0.75...1.00: "battery.100percent.bolt"
        default:          "battery.0percent.bolt"
        }
        @unknown default: "battery.0percent.bolt"
        }
    }
}
