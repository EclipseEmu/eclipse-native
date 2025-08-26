#if canImport(UIKit)
import SwiftUI
import EclipseKit

@MainActor
final class TouchEditorViewModel: ObservableObject {
    @Published var mappings: TouchMappings {
        didSet {
            onChange(mappings)
        }
    }
	let system: System
	let namingConvention: ControlNamingConvention
    let onChange: ControlsProfileUpdateCallback<InputSourceTouchDescriptor>

	struct EditTarget: Identifiable {
		let id: Int
	}

    init(mappings: TouchMappings, system: System, onChange: @escaping ControlsProfileUpdateCallback<InputSourceTouchDescriptor>) {
		self.mappings = mappings
		self.system = system
		self.namingConvention = system.controlNamingConvention
        self.onChange = onChange
	}

	func label(for index: TouchMappings.ControlIndex) -> (String, systemImage: String) {
		let input = switch index {
		case .button(let i): self.mappings.buttons[i].input
		case .directional(let i): self.mappings.directionals[i].input
		}
		return input.label(for: namingConvention)
	}

	@inlinable
	func label(for button: TouchMappings.Button) -> (String, systemImage: String) {
		return button.input.label(for: namingConvention)
	}

	@inlinable
	func label(for directional: TouchMappings.Directional) -> (String, systemImage: String) {
		return directional.input.label(for: namingConvention)
	}

	@inlinable
	func index(of directional: TouchMappings.Directional) -> Int? {
		self.mappings.directionals.firstIndex(of: directional)
	}

	@inlinable
	func index(of button: TouchMappings.Button) -> Int? {
		self.mappings.buttons.firstIndex(of: button)
	}

	@inlinable
	func index(of variant: TouchMappings.Variant) -> Int? {
		self.mappings.variants.firstIndex(of: variant)
	}
}

extension TouchEditorViewModel: Equatable, Hashable {
	nonisolated static func == (lhs: TouchEditorViewModel, rhs: TouchEditorViewModel) -> Bool {
		lhs === rhs
	}

	nonisolated func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
}
#endif
