import SwiftUI
import EclipseKit

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
            CoreSettingsView<Core>(object: object, settings: settings)
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

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    NavigationStack {
        CoreView<TestCore>()
    }
}
