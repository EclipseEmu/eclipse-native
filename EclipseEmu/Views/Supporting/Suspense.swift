import SwiftUI

enum SuspenseStatus<T, E> {
	case pending
	case success(T)
	case failure(E)
}

struct Suspense<T: Sendable, E: Error, Content: View>: View {
	@State var status: SuspenseStatus<T, E> = .pending
	var task: () async throws(E) -> T
	var view: (T) -> Content

	init(task: @escaping () async throws(E) -> T, @ViewBuilder view: @escaping (T) -> Content) {
		self.task = task
		self.view = view
	}

	var body: some View {
		switch status {
		case .pending:
			VStack {
				ProgressView()
			}
			.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
			.task(run)
		case .success(let value):
			view(value)
		case .failure(let error):
			Text(error.localizedDescription)
		}
	}

	func run() async {
		do {
			let value = try await self.task()
			status = .success(value)
		} catch {
			status = .failure(error)
		}
	}
}
