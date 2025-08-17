import EclipseKit
import SwiftUI

struct CoreSettingsBoolView<Settings: CoreSettings>: View {
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
