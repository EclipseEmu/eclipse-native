import EclipseKit
import SwiftUI
import UniformTypeIdentifiers

struct CoreSettingsFileView<Settings: CoreSettings>: View {
    private let coreID: String
    @EnvironmentObject var persistence: Persistence
	@Binding private var settings: Settings
	@Binding private var fileImportType: FileImportRequest?
	private let setting: CoreFileSettingDescriptor<Settings>
	private let fileType: UTType
	@State private var isDeleteFileOpen: Bool = false

    init(coreID: String, settings: Binding<Settings>, setting: CoreFileSettingDescriptor<Settings>, fileImportType: Binding<FileImportRequest?>) {
        self.coreID = coreID
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
	private var fileInputView: some View {
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
    
    private func upload() -> Void {
        self.fileImportType = .init(types: [fileType], allowsMultipleSelection: false, completion: handle)
    }

	@Sendable
	private nonisolated func handle(_ result: Result<[URL], any Error>) {
		guard case .success(let urls) = result, let sourceURL = urls.first else { return }
		Task { @MainActor in
			do {
				let doStopAccessing = sourceURL.startAccessingSecurityScopedResource()
				defer {
					if doStopAccessing {
						sourceURL.stopAccessingSecurityScopedResource()
					}
				}

				if !setting.sha1.isEmpty {
					let hash = try await persistence.files.sha1(for: sourceURL)
					guard setting.sha1.contains(hash) else {
						// FIXME: Surface error
                        print("hash mismatch", hash, setting.sha1)
                        return
					}
				}
                
                // NOTE: for now we'll leave this as just nil, but if cores start needing the file extension, for whatever reason, then we'll need to actually get an extension.
                let fileExtension: String? = nil
                try await persistence.files.overwrite(copying: .other(sourceURL), to: .coreFile(coreID: coreID, fileID: setting.id, fileExtension: fileExtension))
                self.settings[keyPath: setting.target] = .init(id: setting.id, fileExtension: fileExtension)
			} catch {
                // FIXME: Surface error
                print(error)
			}
		}
	}

	private func delete() -> Void {
		Task { @MainActor in
            do {
                if let file = self.settings[keyPath: setting.target] {
                    try await persistence.files.delete(at: .coreFile(coreID: coreID, fileID: file.id, fileExtension: file.fileExtension))
                }
                self.settings[keyPath: setting.target] = nil
            } catch {
                // FIXME: Surface error
                print(error)
            }
		}
	}
}
