import EclipseKit
import SwiftUI

struct CoreSettingsRadioView<Settings: CoreSettings>: View {
	@Binding private var settings: Settings
	private let setting: CoreRadioSettingDescriptor<Settings>
	private let selection: Binding<Int>

	init(settings: Binding<Settings>, setting: CoreRadioSettingDescriptor<Settings>) {
		self._settings = settings
		self.setting = setting
		self.selection = .init(get: {
			settings.wrappedValue[keyPath: setting.target]
		}, set: { newValue in
			settings.wrappedValue[keyPath: setting.target] = newValue
		})
	}

	var body: some View {
		Picker(selection: selection) {
			ForEach(setting.options) { option in
				Text(option.displayName).tag(option.id)
			}
		} label: {
			Text(setting.displayName)
		}
	}
}
