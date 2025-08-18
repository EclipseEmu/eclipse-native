import SwiftUI
import EclipseKit
import mGBAEclipseCore

enum Core: Int16, RawRepresentable, Identifiable, Hashable, CaseIterable, Codable {
	private static let decoder: JSONDecoder = JSONDecoder()
	private static let encoder: JSONEncoder = JSONEncoder()

	case testCore
	case mGBA

	@usableFromInline
	var id: Int16 { self.rawValue }

	var type: any CoreProtocol.Type {
		switch self {
		case .mGBA: mGBAEclipseCore.self
		case .testCore: TestCore.self
		}
	}

	@MainActor
	@ViewBuilder
	var settingsView: some View {
		switch self {
		case .mGBA: CoreView<mGBAEclipseCore>()
		case .testCore: CoreView<TestCore>()
		}
	}

	@MainActor
	@ViewBuilder
	func emulationView(with data: GamePlaybackData) -> some View {
		switch self {
		case .mGBA: EmulationLoaderView<mGBAEclipseCore>(data: data)
		case .testCore: EmulationLoaderView<TestCore>(data: data)
		}
	}
}
