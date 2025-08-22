import SwiftUI
import EclipseKit
import CoreData

struct CoreView<Core: CoreProtocol>: View {
    @EnvironmentObject private var persistence: Persistence
    @State private var state: LoadingState = .loading
    
    private enum LoadingState {
        case loading
        case success(target: CoreSettingsObject, settings: Core.Settings)
        case failure(any Error)
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
            
            content
        }
        .formStyle(.grouped)
        .navigationTitle(Core.name)
    }
    
    @ViewBuilder
    var content: some View {
        switch state {
        case .loading:
            VStack {
                ProgressView()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .task(load)
        case .failure(let error):
            Text(error.localizedDescription)
        case .success(target: let object, settings: let settings):
            CoreSettingsView2<Core>(object: object, settings: settings)
        }
    }
    
    private func load() async {
        self.state = .loading
        do {
            let object = try await getObject()
            let settings: Core.Settings = if let data = object.data {
                try Core.Settings.decode(data, version: object.version)
            } else {
                Core.Settings()
            }
            self.state = .success(target: object, settings: settings)
        } catch {
            self.state = .failure(error)
        }
    }
    
    private func getObject() async throws -> CoreSettingsObject {
        let fetchRequest = CoreSettingsObject.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "coreID = %@", Core.id)
        if let object = try persistence.mainContext.fetch(fetchRequest).first {
            print("using existing object")
            return object
        }
        
        print("creating new object")
        let objectBox = try await persistence.objects.createCoreSettings(Core.self)
        return try objectBox.get(in: persistence.mainContext)
    }
}

private struct CoreSettingsView2<Core: CoreProtocol>: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject private var object: CoreSettingsObject
    @State private var settings: Core.Settings
    @State private var fileImportType: FileImportType?
    @State private var updateTask: Task<Void, Never>?
    
    private let descriptor: CoreSettingsDescriptor<Core.Settings> = Core.Settings.descriptor

    init(object: CoreSettingsObject, settings: Core.Settings) {
        self.object = object
        self.settings = settings
    }
    
    var body: some View {
        Group {
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
        }
        .multiFileImporter($fileImportType)
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

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    NavigationStack {
        CoreView<TestCore>()
    }
}
