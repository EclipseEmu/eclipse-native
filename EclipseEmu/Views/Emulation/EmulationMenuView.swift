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
			Picker("Speed", selection: $speedValue) {
				ForEach(EmulationSpeed.allCases, id: \.rawValue) { value in
					value.tag(value)
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				CancelButton("Done", action: dismissAction.callAsFunction)
			}
			ToolbarItem(placement: .confirmationAction) {
				ToggleButton(role: .destructive, value: $isQuitConfirmationOpen) {
					Label("Quit", systemImage: "power")
				}
				.confirmationDialog("Quit Game", isPresented: $isQuitConfirmationOpen) {
					Button("Cancel", role: .cancel, action: {})
					Button("Quit") {
						dismissAction()
						quit()
					}
				} message: {
					Text("Are you sure you want to quit the game? All unsaved progress may be lost.")
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
