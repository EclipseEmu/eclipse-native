import Foundation
import GameController
import EclipseKit

enum InputSourceTouchVersion: Int16, VersionProtocol {
    case v1 = 1
    
    static let latest: Self = .v1
}

struct InputSourceTouchDescriptor: InputSourceDescriptorProtocol {
    typealias Bindings = TouchMappings
	typealias Object = TouchProfileObject

	static func encode(_ bindings: TouchMappings, encoder: JSONEncoder, into object: TouchProfileObject) throws {
		object.data = try encoder.encode(bindings)
	}

	static func decode(_ data: TouchProfileObject, decoder: JSONDecoder) throws -> TouchMappings {
        guard let version = data.version, let data = data.data else {
            return .init(variants: [], directionals: [], buttons: [])
        }
        
		return switch version {
		case .v1: try decoder.decode(TouchMappings.self, from: data)
		}
	}

	func obtain(for game: GameObject) -> TouchProfileObject? {
		game.touchProfile
	}
    
    func obtain(for system: System, persistence: Persistence, settings: Settings) -> TouchProfileObject? {
#if canImport(UIKit)
        return settings.touchSystemProfiles[system]?.tryGet(in: persistence.mainContext)
#else
        return nil
#endif
    }

	func predicate(system: System) -> NSPredicate {
		NSPredicate(format: "rawSystem = %d", system.rawValue)
	}

	static func defaults(for system: System) -> TouchMappings {
		switch system {
		case .gba:
			TouchMappings(
				variants: [
					.init(
						sizing: .landscapeRegular,
						menu: .init(xOrigin: .right, yOrigin: .top, xOffset: 0, yOffset: 0, size: 50),
						screenOffset: .init(x: 0, y: 0),
						elements: [
							.init(control: .directional(0), rect: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 87.5, size: 125)),
							.init(control: .button(0), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 50, yOffset: 75, size: 50)),
							.init(control: .button(1), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 0, yOffset: 125, size: 50)),
							.init(control: .button(2), rect: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 225, size: 50)),
							.init(control: .button(3), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 0, yOffset: 225, size: 50)),
							.init(control: .button(4), rect: .init(xOrigin: .center, yOrigin: .bottom, xOffset: 41, yOffset: 0, size: 50)),
							.init(control: .button(5), rect: .init(xOrigin: .center, yOrigin: .bottom, xOffset: -41, yOffset: 0, size: 50)),
						]
					),
					.init(
						sizing: .portraitRegular,
						menu: .init(xOrigin: .left, yOrigin: .top, xOffset: 0, yOffset: 0, size: 50),
						screenOffset: .init(x: 0, y: 0),
						elements: [
							.init(control: .directional(0), rect: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 87.5, size: 125)),
							.init(control: .button(0), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 50, yOffset: 75, size: 50)),
							.init(control: .button(1), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 0, yOffset: 125, size: 50)),
							.init(control: .button(2), rect: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 225, size: 50)),
							.init(control: .button(3), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 0, yOffset: 225, size: 50)),
							.init(control: .button(4), rect: .init(xOrigin: .center, yOrigin: .bottom, xOffset: 41, yOffset: 0, size: 50)),
							.init(control: .button(5), rect: .init(xOrigin: .center, yOrigin: .bottom, xOffset: -41, yOffset: 0, size: 50)),
						]
					),
					.init(
						sizing: .landscapeCompact,
						menu: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 0, size: 50),
						screenOffset: .init(x: 0, y: 0),
						elements: [
							.init(control: .directional(0), rect: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 87.5, size: 125)),
							.init(control: .button(0), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 50, yOffset: 75, size: 50)),
							.init(control: .button(1), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 0, yOffset: 125, size: 50)),
							.init(control: .button(2), rect: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 225, size: 50)),
							.init(control: .button(3), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 0, yOffset: 225, size: 50)),
							.init(control: .button(4), rect: .init(xOrigin: .center, yOrigin: .bottom, xOffset: 41, yOffset: 0, size: 50)),
							.init(control: .button(5), rect: .init(xOrigin: .center, yOrigin: .bottom, xOffset: -41, yOffset: 0, size: 50)),
						]
					),
					.init(
						sizing: .portraitCompact,
						menu: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 0, size: 50),
						screenOffset: .init(x: 0, y: -100),
						elements: [
							.init(control: .directional(0), rect: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 87.5, size: 125)),
							.init(control: .button(0), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 50, yOffset: 75, size: 50)),
							.init(control: .button(1), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 0, yOffset: 125, size: 50)),
							.init(control: .button(2), rect: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 0, yOffset: 225, size: 50)),
							.init(control: .button(3), rect: .init(xOrigin: .right, yOrigin: .bottom, xOffset: 0, yOffset: 225, size: 50)),
							.init(control: .button(4), rect: .init(xOrigin: .center, yOrigin: .bottom, xOffset: 41, yOffset: 0, size: 50)),
							.init(control: .button(5), rect: .init(xOrigin: .center, yOrigin: .bottom, xOffset: -41, yOffset: 0, size: 50)),
						]
					)
				],
				directionals: [
					.init(id: 0, input: .dpad, deadzone: 0.5, style: .dpad),
				],
				buttons: [
					.init(id: 0, input: .faceButtonDown),
					.init(id: 1, input: .faceButtonRight),
					.init(id: 2, input: .leftShoulder),
					.init(id: 3, input: .rightShoulder),
					.init(id: 4, input: .start),
					.init(id: 5, input: .select),
				]
			)
		default: .init(variants: [], directionals: [], buttons: [])
        }
    }
}

/// MARK: Mappings Definitions

struct TouchMappings: Codable {
	var variants: [TouchMappings.Variant]
	var directionals: [TouchMappings.Directional]
	var buttons: [TouchMappings.Button]

	struct Variant: Identifiable, Codable {
		var id: TouchMappings.VariantSizing { self.sizing }
		var sizing: TouchMappings.VariantSizing
		var menu: TouchMappings.RelativeRect
		var screenOffset: TouchMappings.ScreenOffset
		var elements: [TouchMappings.Element]
	}

	enum ControlIndex: Identifiable, Codable, Hashable, Comparable {
		case button(Int)
		case directional(Int)

		@usableFromInline
		var id: Int {
			switch self {
			case .button(let i): i
			case .directional(let i): i | (1 << (Int.bitWidth - 1))
			}
		}

		@inlinable
		static func < (lhs: TouchMappings.ControlIndex, rhs: TouchMappings.ControlIndex) -> Bool {
			lhs.id < rhs.id
		}
	}

	struct Element: Identifiable, Codable, Equatable, Comparable {
		@usableFromInline
		var id: Int { self.control.id }
		var control: TouchMappings.ControlIndex
		var rect: TouchMappings.RelativeRect

		@inlinable
		static func == (lhs: TouchMappings.Element, rhs: TouchMappings.Element) -> Bool {
			lhs.id == rhs.id
		}

		@inlinable
		static func < (lhs: TouchMappings.Element, rhs: TouchMappings.Element) -> Bool {
			lhs.control < rhs.control
		}
	}

	enum VariantSizing: UInt8, RawRepresentable, Comparable, Codable, CaseIterable {
		case any = 0
		case portraitCompact = 1
		case landscapeCompact = 2
		case portraitRegular = 3
		case landscapeRegular = 4

		static func < (lhs: TouchMappings.VariantSizing, rhs: TouchMappings.VariantSizing) -> Bool {
			lhs.rawValue < rhs.rawValue
		}

		func fits(in other: TouchMappings.VariantSizing) -> Bool {
			return switch other {
			case .any: true
			case .portraitCompact, .landscapeCompact: other == .any
			case .portraitRegular, .landscapeRegular: switch self {
			case .landscapeCompact, .portraitCompact, .any: true
			default: self == other
			}
			}
		}
	}

	struct ScreenOffset: Codable, Equatable {
		var x: Float
		var y: Float

		static let zero = Self(x: 0, y: 0)
	}

	struct RelativeRect: Codable, Equatable {
		var xOrigin: XOrigin
		var yOrigin: YOrigin
		var xOffset: Float
		var yOffset: Float
		var size: Float

		static let zero = Self(xOrigin: .left, yOrigin: .top, xOffset: 0, yOffset: 0, size: 0)

		enum YOrigin: UInt8, Codable, Equatable, CaseIterable {
			case top = 0
			case center = 1
			case bottom = 2
		}

		enum XOrigin: UInt8, Codable, Equatable, CaseIterable{
			case left = 0
			case center = 1
			case right = 2
		}
	}

	struct Button: Codable, Identifiable, Equatable {
		var id: UInt32
		var input: CoreInput
		var direction: ControlMappingDirection
		var visible: Bool

		init(id: UInt32, input: CoreInput, direction: ControlMappingDirection = .none, visible: Bool = true) {
			self.id = id
			self.input = input
			self.direction = direction
			self.visible = visible
		}
	}

	struct Directional: Codable, Identifiable, Equatable {
		var id: UInt32
		var input: CoreInput
		var deadzone: Float
		var style: Self.Style

		enum Style: UInt8, Codable {
			case dpad = 1
			case joystick = 2
		}
	}
}

extension TouchMappings {
	init(
		variants: Set<TouchMappings.Variant>,
		directionals: [TouchMappings.Directional],
		buttons: [TouchMappings.Button],
	) {
		self.variants = variants.sorted { $0 > $1 }
		self.directionals = directionals
		self.buttons = buttons
	}

	borrowing func variantIndex(for layoutClass: TouchMappings.VariantSizing) -> Int {
		// FIXME: Test this more.
		return variants.firstIndex(where: { $0.sizing == layoutClass })
            ?? variants.firstIndex(where: { $0.sizing.fits(in: layoutClass) })
            ?? variants.lastIndex(where: { $0.sizing == .any })
            ?? (variants.isEmpty ? -1 : 0)
	}

	mutating func insert(_ element: inout TouchMappings.Button) -> Int {
		let maxID = buttons.reduce(0, { max($0, $1.id) })
		element.id = maxID + 1
		buttons.append(element)
		return buttons.count - 1
	}

	mutating func insert(_ element: inout TouchMappings.Directional) -> Int {
		let maxID = buttons.reduce(0, { max($0, $1.id) })
		element.id = maxID + 1
		directionals.append(element)
		return directionals.count - 1
	}

	@discardableResult
	mutating func insertVariant(for sizing: VariantSizing) -> Int {
		var newLayout = TouchMappings.Variant.zero
		newLayout.sizing = sizing
		return variants.sortedInsert(newLayout)
	}

	@available(*, deprecated, renamed: "insert", message: "edits happen directly, now")
	mutating func upsertDirectional(_ element: inout TouchMappings.Directional, at target: EditorTarget<Int>) {
		switch target {
		case .create:
			let maxID = directionals.reduce(0, { max($0, $1.id) })
			element.id = maxID + 1
			directionals.append(element)
		case .edit(let index):
			directionals[index] = element
		}
	}

	@available(*, deprecated, renamed: "insert", message: "edits happen directly, now")
	mutating func upsertButton(_ element: inout TouchMappings.Button, at target: EditorTarget<Int>) {
		switch target {
		case .create:
			let maxID = buttons.reduce(0, { max($0, $1.id) })
			element.id = maxID + 1
			buttons.append(element)
		case .edit(let index):
			buttons[index] = element
		}
	}

	@inlinable
	mutating func removeButtons(_ indexSet: IndexSet) {
		let indices: [Int] = indexSet.sorted()
		guard !indices.isEmpty else { return }

		var variantIndex = 0
		while variantIndex < self.variants.count {
			self.variants[variantIndex].sortElements()

			// skip directionals
			var i = 0
			while i < self.variants[variantIndex].elements.count, case .directional = self.variants[variantIndex].elements[i].control {
				i += 1
			}

			// FIXME: this looks so easily optimizable...
			outer: while
				i < self.variants[variantIndex].elements.count,
				case .button(let controlIndex) = self.variants[variantIndex].elements[i].control
			{
				var shift = 0
				for index in indices {
					shift += index <= controlIndex ? 1 : 0
					if index == controlIndex {
						self.variants[variantIndex].elements.remove(at: i)
						continue outer
					}
				}

				self.variants[variantIndex].elements[i].control = .button(controlIndex - shift)
				i += 1
			}

			variantIndex += 1
		}

		buttons.remove(atOffsets: indexSet)
	}

	@inlinable
	mutating func removeDirectionals(_ indexSet: IndexSet) {
		let indices: [Int] = .init(indexSet)
		guard !indices.isEmpty else { return }

		var variantIndex = 0
		while variantIndex < self.variants.count {
			self.variants[variantIndex].sortElements()

			// FIXME: this looks so easily optimizable...
			// 	essentially just grab an index into the indices array, and check if the value at the index is <= the current control index.
			//	if it is less than or equal to, bump the removal count. share the removal count between iterations.
			var i = 0
			outer: while
				i < self.variants[variantIndex].elements.count,
				case .directional(let controlIndex) = self.variants[variantIndex].elements[i].control
			{
				var shift = 0
				for index in indices {
					shift += index <= controlIndex ? 1 : 0
					if index == controlIndex {
						self.variants[variantIndex].elements.remove(at: i)
						continue outer
					}
				}

				self.variants[variantIndex].elements[i].control = .directional(controlIndex - shift)
				i += 1
			}
			variantIndex += 1
		}

		directionals.remove(atOffsets: indexSet)
	}

	borrowing func availableControls(for variantIndex: Int, including: ControlIndex? = nil) -> (directionals: IndexSet, buttons: IndexSet) {
		var directionalsSet = IndexSet(0..<directionals.count)
		var buttonsSet = IndexSet(0..<buttons.count)

		// remove elements that we already have in the variant, but keep the currently selected one.
		for element in variants[variantIndex].elements {
			switch element.control {
			case including: continue
			case .directional(let i): directionalsSet.remove(i)
			case .button(let i): buttonsSet.remove(i)
			}
		}

		return (directionals: directionalsSet, buttons: buttonsSet)
	}
}

extension TouchMappings.Variant: Comparable, Hashable {
	static let zero =  TouchMappings.Variant(
		sizing: .any,
		menu: .init(xOrigin: .left, yOrigin: .bottom, xOffset: 16, yOffset: 16, size: 50),
		screenOffset: .zero,
		elements: []
	)

	static func < (lhs: TouchMappings.Variant, rhs: TouchMappings.Variant) -> Bool {
		lhs.sizing < rhs.sizing
	}

	func hash(into hasher: inout Hasher) {
		self.sizing.hash(into: &hasher)
	}

	static func == (lhs: TouchMappings.Variant, rhs: TouchMappings.Variant) -> Bool {
		return lhs.sizing == rhs.sizing
	}

	mutating func sortElements() {
		self.elements.sort()
	}

	@inlinable
	@discardableResult
	mutating func insert(control: TouchMappings.ControlIndex) -> Int {
		elements.sortedInsert(.init(control: control, rect: .init(xOrigin: .left, yOrigin: .top, xOffset: 0, yOffset: 0, size: 50)))
	}

	@inlinable
	mutating func update(at index: Int, rect: TouchMappings.RelativeRect) {
		elements[index].rect = rect
	}

	@available(*, deprecated, renamed: "update", message: "use the seperate methods.")
	mutating func upsert(
		target: EditorTarget<Int>,
		control: TouchMappings.ControlIndex,
		rect: TouchMappings.RelativeRect
	) {
		let updatedElement = TouchMappings.Element(control: control, rect: rect)
		switch target {
		case .create: elements.sortedInsert(updatedElement)
		case .edit(let i): elements[i] = updatedElement
		}
	}
}

#if canImport(UIKit)
import UIKit

extension TouchMappings.VariantSizing {
	init(screenBounds: CGSize, horizontalClass: UIUserInterfaceSizeClass, verticalClass: UIUserInterfaceSizeClass) {
		self = switch (horizontalClass, verticalClass) {
		case (.regular, .regular):			screenBounds.width < screenBounds.height ? .portraitRegular : .landscapeRegular
		case (.compact, .compact): 			screenBounds.width < screenBounds.height ? .portraitCompact : .landscapeCompact
		case (.regular, .compact):			.landscapeCompact
		case (.compact, .regular):			.portraitCompact
		case (.unspecified, .regular):		.portraitCompact
		case (.unspecified, .compact):		.portraitCompact
		case (.regular, .unspecified):		.landscapeCompact
		case (.compact, .unspecified):		.landscapeCompact
		case (.unspecified, .unspecified): 	.any
		@unknown default: 					.any
		}
	}
}
#endif

#if DEBUG
extension TouchMappings.RelativeRect.XOrigin: CustomStringConvertible {
	var description: String {
		switch self {
		case .center: "center"
		case .left: "left"
		case .right: "right"
		}
	}
}

extension TouchMappings.RelativeRect.YOrigin: CustomStringConvertible {
	var description: String {
		switch self {
		case .center: "center"
		case .top: "top"
		case .bottom: "bottom"
		}
	}
}

extension TouchMappings.ScreenOffset: CustomStringConvertible {
	var description: String {
		"(\(self.x), \(self.y))"
	}
}

extension TouchMappings.VariantSizing: CustomStringConvertible {
	var description: String {
		switch self {
		case .any: ".any"
		case .portraitCompact: ".portraitCompact"
		case .landscapeCompact: ".landscapeCompat"
		case .portraitRegular: ".portraitRegular"
		case .landscapeRegular: ".landscapeRegular"
		}
	}
}

extension TouchMappings.RelativeRect: CustomStringConvertible {
	var description: String {
		"(.\(self.xOrigin)(\(self.xOffset)), .\(self.yOrigin)(\(self.yOffset), x\(self.size)"
	}
}

extension TouchMappings.ControlIndex: CustomStringConvertible {
	var description: String {
		switch self {
		case .button(let i): ".button(\(i))"
		case .directional(let i): ".directional(\(i))"
		}
	}
}

extension TouchMappings.Element: CustomStringConvertible {
	var description: String {
		self.control.description
	}
}
#endif

