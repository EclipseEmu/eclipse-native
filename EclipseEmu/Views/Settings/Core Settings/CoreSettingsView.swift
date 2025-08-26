import SwiftUI
import EclipseKit

struct CoreSettingsView<Core: CoreProtocol>: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject private var object: CoreSettingsObject
    @State private var settings: Core.Settings
    @State private var fileImportType: FileImportRequest?
    @State private var updateTask: Task<Void, Never>?
    
    private let descriptor: CoreSettingsDescriptor<Core.Settings> = Core.Settings.descriptor

    init(object: CoreSettingsObject, settings: Core.Settings) {
        self.object = object
        self.settings = settings
    }
    
    var body: some View {
        ForEach(descriptor.sections) { section in
            Section {
                ForEach(section.settings) { setting in
                    switch setting {
                    case .bool(let inner):
                        CoreSettingsBoolView(settings: $settings, setting: inner)
                    case .file(let inner):
                        CoreSettingsFileView(coreID: Core.id, settings: $settings, setting: inner, fileImportType: $fileImportType)
                    case .radio(let inner):
                        CoreSettingsRadioView(settings: $settings, setting: inner)
                    @unknown default: EmptyView()
                    }
                }
            } header: {
                Text(section.title)
            }
        }
        .fileImporter($fileImportType)
        .onChange(of: settings, perform: save)
    }
    
    func save(_ newValue: Core.Settings) {
        self.updateTask?.cancel()
        self.updateTask = Task {
            do {
                try await Task.sleep(for: .seconds(1))
                try await persistence.objects.updateCoreSettings(Core.self, target: .init(object), settings: newValue)
                print("saved core settings")
            } catch is CancellationError {} catch {
                // FIXME: Surface error
                print("failed to save core settings:", error)
            }
        }
    }
}
