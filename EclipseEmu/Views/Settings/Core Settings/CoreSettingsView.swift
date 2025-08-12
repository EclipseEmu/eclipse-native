import EclipseKit
import SwiftUI
import UniformTypeIdentifiers

private struct HorizontalDetailText: View {
	let title: LocalizedStringKey
	let subtitle: String
    
	var body: some View {
		LabeledContent(title) {
			Text(subtitle)
				.foregroundStyle(.secondary)
		}
	}
}

struct CoreSettingsView<Core: CoreProtocol & ~Copyable>: View {
	let descriptor: CoreSettingsDescriptor<Core.Settings>
	@State var settings: Core.Settings
	@State var fileImportType: FileImportType?

	init() {
		self.descriptor = Core.Settings.descriptor
		self.settings = .init()
	}

	var body: some View {
		Form {
			Section {
                LabeledContent("CORE_NAME") { Text(Core.name) }
                LabeledContent("CORE_DEVELOPER") { Text(Core.developer) }
                LabeledContent("CORE_VERSION") { Text(Core.version) }
				Link(destination: Core.sourceCodeRepository) {
					Label("SOURCE_CODE", systemImage: "folder")
				}
			} header: {
				Text("INFO")
			}

			ForEach(descriptor.sections) { section in
				Section {
					ForEach(section.settings) { setting in
						switch setting {
						case .bool(let inner):
							BoolSettingView(settings: $settings, setting: inner)
						case .file(let inner):
							FileSettingView(settings: $settings, setting: inner, fileImportType: $fileImportType)
						case .radio(let inner):
							RadioSettingView(settings: $settings, setting: inner)
						@unknown default: EmptyView()
						}
					}
				} header: {
					Text(section.title)
				}
			}
		}
		.formStyle(.grouped)
		.navigationTitle(Core.name)
		.multiFileImporter($fileImportType)
		.onChange(of: settings, perform: save)
	}

	func save(_: Core.Settings) {
		print(settings)
	}
}

private struct BoolSettingView<Settings: CoreSettings>: View {
	@Binding private var settings: Settings
	private let setting: CoreBoolSettingDescriptor<Settings>
	private let isOn: Binding<Bool>

	init(settings: Binding<Settings>, setting: CoreBoolSettingDescriptor<Settings>) {
		self._settings = settings
		self.setting = setting
		self.isOn = .init(get: {
			settings.wrappedValue[keyPath: setting.target]
		}, set: { newValue in
			settings.wrappedValue[keyPath: setting.target] = newValue
		})
	}

	var body: some View {
		Toggle(isOn: isOn) {
			Text(setting.displayName)
		}
	}
}

private struct RadioSettingView<Settings: CoreSettings>: View {
	@Binding private var settings: Settings
	private let setting: CoreRadioSettingDescriptor<Settings>
	private let selection: Binding<Int>

	init(settings: Binding<Settings>, setting: CoreRadioSettingDescriptor<Settings>) {
		self._settings = settings
		self.setting = setting
		self.selection = .init(get: {
			settings.wrappedValue[keyPath: setting.target]
		}, set: { newValue in
			settings.wrappedValue[keyPath: setting.target] = newValue
		})
	}

	var body: some View {
		Picker(selection: selection) {
			ForEach(setting.options) { option in
				Text(option.displayName).tag(option.id)
			}
		} label: {
			Text(setting.displayName)
		}
	}
}

private struct FileSettingView<Settings: CoreSettings>: View {
	@EnvironmentObject var persistence: Persistence
	@Binding private var settings: Settings
	@Binding private var fileImportType: FileImportType?
	private let setting: CoreFileSettingDescriptor<Settings>
	private let fileType: UTType
	@State private var isDeleteFileOpen: Bool = false

	init(settings: Binding<Settings>, setting: CoreFileSettingDescriptor<Settings>, fileImportType: Binding<FileImportType?>) {
		self._settings = settings
		self.setting = setting
		self._fileImportType = fileImportType
		self.fileType = switch setting.type {
		case .binary: UTType.data
		}
	}

	var body: some View {
		LabeledContent {
			fileInputView
		} label: {
			if setting.required {
				Text(setting.displayName)
				Text("FIELD_REQUIRED")
					.font(.caption)
					.foregroundStyle(.secondary)
			} else {
				Text(setting.displayName)
			}
		}
	}

	@ViewBuilder
	var fileInputView: some View {
		if settings[keyPath: setting.target] != nil {
			Menu("MANAGE") {
				Button(action: upload) {
					Label("REPLACE", systemImage: "doc")
				}
				ToggleButton(role: .destructive, value: $isDeleteFileOpen) {
					Label("DELETE", systemImage: "trash")
				}
			}
			.confirmationDialog("DELETE_FILE_TITLE", isPresented: $isDeleteFileOpen) {
				Button("DELETE", role: .destructive, action: delete)
				Button("CANCEL", role: .cancel, action: {})
			} message: {
				Text("DELETE_FILE_MESSAGE")
			}
		} else {
			Button("UPLOAD", action: upload)
		}
	}

	@Sendable
	nonisolated func handle(_ result: Result<[URL], any Error>) {
		guard case .success(let urls) = result, let sourceURL = urls.first else { return }
		Task { @MainActor in
			do {
				let fileExtension = sourceURL.fileExtension()
				let destination = CoreSettingsFile(id: setting.id, fileExtension: fileExtension)
				guard let destinationURL = self.resolveFile(file: destination) else { return }

				let doStopAccessing = sourceURL.startAccessingSecurityScopedResource()
				defer {
					if doStopAccessing {
						sourceURL.stopAccessingSecurityScopedResource()
					}
				}

				if !setting.sha1.isEmpty {
					let hash = try await persistence.files.sha1(for: sourceURL)
					guard setting.sha1.contains(hash) else {
						// FIXME: Show an error
						return
					}
				}

				try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
				self.settings[keyPath: setting.target] = destination
			} catch {
				print(error)
			}
		}
	}

	func upload() -> Void {
		self.fileImportType = .init(types: [fileType], allowsMultipleSelection: false, completion: handle)
	}

	func delete() -> Void {
		Task { @MainActor in
			if let file = self.settings[keyPath: setting.target], let url = resolveFile(file: file) {
				try? FileManager.default.removeItem(at: url)
			}
			self.settings[keyPath: setting.target] = nil
		}
	}

	func resolveFile(file: CoreSettingsFile) -> URL? {
		let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		let path = "\(file.id)\(file.fileExtension ?? "")"
		return url.appending(path: path)
	}
}

#Preview {
	NavigationStack {
		CoreSettingsView<TestCore>()
	}
}
