import SwiftUI

enum InlineSuspenseStatus<T> {
	case pending
	case success(T)
}

struct InlineSuspense<T: Sendable, Content: View>: View {
	@State var status: InlineSuspenseStatus<T> = .pending
	var task: () async -> T
	var view: (T) -> Content

	init(task: @escaping () async -> T, @ViewBuilder view: @escaping (T) -> Content) {
		self.task = task
		self.view = view
	}

	var body: some View {
		switch status {
		case .pending:
			ProgressView().task(run)
		case .success(let value):
			view(value)
		}
	}

	func run() async {
		let value = await self.task()
		status = .success(value)
	}
}
