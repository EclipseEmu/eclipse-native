import EclipseKit
import SwiftUI

struct EditCheatView: View {
    private let game: GameObject
    private let cheatFormats: [CoreCheatFormat]
    private let cheat: CheatObject?
    private let isCreatingCheat: Bool

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: Persistence
    @State var label: String
    @State var format: CoreCheatFormat
    @State var formatter: CheatFormatter
    @State var code: String
    @State var enabled: Bool = true
    @State var isCodeValid: Bool = false

    init(cheat: CheatObject?, game: GameObject, cheatFormats: [CoreCheatFormat]) {
        self.cheat = cheat
        self.game = game
        self.cheatFormats = cheatFormats
        self.isCreatingCheat = cheat == nil

        if let cheat {
            let format = cheatFormats.first { $0.id == cheat.type }!
            self.format = format
            self.formatter = format.makeFormatter()
            self.label = cheat.label ?? ""
            self.code = cheat.code ?? ""
            self.enabled = cheat.enabled
            self.isCodeValid = true
        } else {
            let format = cheatFormats[0]
            self.format = cheatFormats[0]
            self.formatter = format.makeFormatter()
            self.label = ""
            self.code = ""
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("CHEAT_NAME", text: self.$label)
                    Toggle("CHEAT_ENABLED", isOn: self.$enabled)
                } header: {
#if !os(macOS)
                    Text("CHEAT_NAME_AND_STATE")
#endif
                }

                Section {
                    Picker("CHEAT_FORMAT", selection: self.$format) {
                        ForEach(self.cheatFormats, id: \.id) { format in
							Text(format.name).tag(format)
                        }
                    }

#if os(macOS)
                    LabeledContent("CHEAT_CODE") {
                        CheatCodeField(value: self.$code, formatter: self.$formatter)
                    }
#else
                    CheatCodeField(value: self.$code, formatter: self.$formatter)
#endif
                } header: {
#if !os(macOS)
                    Text("CHEAT_CODE")
#endif
                } footer: {
					Text("CHEAT_CORE_FORMAT_MESSAGE \"\(self.format.pattern.uppercased())\"")
                }
            }
            .formStyle(.grouped)
            .onChange(of: self.format, perform: self.formatChanged)
            .onChange(of: self.code, perform: self.codeChanged)
            .navigationTitle(self.isCreatingCheat ? "ADD_CHEAT" : "EDIT_CHEAT")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#else
                .padding()
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("CANCEL", role: .cancel) {
                            self.dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("DONE", action: self.save)
                            .disabled(self.label.isEmpty || !self.isCodeValid)
                    }
                }
        }
    }

    func formatChanged(value: CoreCheatFormat) {
        self.formatter = value.makeFormatter()
        self.code = self.formatter.formatInput(value: self.code)
        self.isCodeValid = self.formatter.validate(value: self.code)
    }

    func codeChanged(value: String) {
        self.isCodeValid = self.formatter.validate(value: value)
    }

    func save() {
        guard self.isCodeValid && !self.label.isEmpty else { return }

        let format = self.format.id
        let normalizedCode = self.format.normalizeCode(string: self.code)

        Task {
            do {
                if let cheat {
                    try await persistence.objects.update(
                        cheat: .init(cheat),
                        name: self.label,
                        code: self.format.normalizeCode(string: self.code),
                        format: self.format.id,
                        enabled: self.enabled
                    )
                } else {
                    try await persistence.objects.createCheat(
                        name: self.label,
                        code: normalizedCode,
                        format: format,
                        isEnabled: self.enabled,
                        for: .init(self.game)
                    )
                }
                self.dismiss()
            } catch {
                print(error)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        NavigationStack {
            EditCheatView(cheat: nil, game: game, cheatFormats: [])
        }
    }
}
