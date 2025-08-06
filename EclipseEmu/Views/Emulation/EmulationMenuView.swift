import SwiftUI

struct EmulationMenuView: View {
	@Environment(\.dismiss) var dismissAction: DismissAction
	@State var isQuitConfirmationOpen: Bool = false
	@State var speedValue: EmulationSpeed = .x1_00

	let quit: () -> Void

	init(quit: @MainActor @escaping () -> Void) {
		self.quit = quit
	}

	var body: some View {
		Form {
			Picker("SPEED", selection: $speedValue) {
				ForEach(EmulationSpeed.allCases, id: \.rawValue) { value in
					value.tag(value)
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				CancelButton("DONE", action: dismissAction.callAsFunction)
			}
			ToolbarItem(placement: .confirmationAction) {
				ToggleButton(role: .destructive, value: $isQuitConfirmationOpen) {
					Label("QUIT", systemImage: "power")
				}
				.confirmationDialog("QUIT_GAME_TITLE", isPresented: $isQuitConfirmationOpen) {
					Button("CANCEL", role: .cancel, action: {})
					Button("QUIT") {
						dismissAction()
						quit()
					}
				} message: {
					Text("QUIT_GAME_MESSAGE")
				}
			}
		}
	}
}

#Preview {
	NavigationStack {
		EmulationMenuView(quit: {})
	}
}
