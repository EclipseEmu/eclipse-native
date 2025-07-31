import SwiftUI

private enum ControlsProfileLoaderError: LocalizedError {
	case decodingError(any Error)
}

private enum ControlsProfileLoaderEncoder {
    static let encoder = JSONEncoder()
}


typealias ControlsProfileUpdateCallback<InputSource: InputSourceDescriptorProtocol> = (InputSource.Bindings) -> Void

@MainActor
struct ControlsProfileLoader<InputSource: InputSourceDescriptorProtocol, Content: View>: View {
    @EnvironmentObject private var persistence: Persistence
    @ObservedObject var object: InputSource.Object
	let content: (@escaping ControlsProfileUpdateCallback<InputSource>, InputSource.Bindings) -> Content
	@State private var loadingState: LoadingState = .pending
    @State private var updateTask: Task<Void, any Error>?
    
	private enum LoadingState {
		case pending
		case failure(ControlsProfileLoaderError)
		case success(InputSource.Bindings)
	}

	init(_ object: InputSource.Object, @ViewBuilder content: @escaping (@escaping ControlsProfileUpdateCallback<InputSource>, InputSource.Bindings) -> Content) {
		self.object = object
		self.content = content
	}

	var body: some View {
        loader
            .onAppear(perform: load)
	}

	@ViewBuilder
	private var loader: some View {
		switch loadingState {
		case .pending:
			ProgressView()
		case .failure(let error):
			ContentUnavailableMessage.error(error: error)
		case .success(let bindings):
            content(save, bindings)
		}
	}

	private func load() {
		do {
			let bindings = try InputSource.decode(object, decoder: ControlBindingsManager.decoder)
            self.loadingState = .success(bindings)
		} catch {
			self.loadingState = .failure(.decodingError(error))
		}
	}
    
    private func save(bindings: InputSource.Bindings) {
        updateTask?.cancel()
        updateTask = Task {
            do {
                try await Task.sleep(for: .seconds(1))
                try InputSource.encode(bindings, encoder: ControlsProfileLoaderEncoder.encoder, into: object)
                try persistence.mainContext.save()
                print("saved profile")
            } catch {
                // FIXME: Surface error
                print("failed to save profile:", error)
            }
        }
    }
}

