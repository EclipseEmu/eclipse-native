import EclipseKit
import SwiftUI

struct CheatEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var persistence: Persistence

    private let game: GameObject
    private let cheatFormats: [CoreCheatFormat]
    private let target: EditorTarget<CheatObject>
    private let title: LocalizedStringKey

    @State private var label: String
    @State private var format: CoreCheatFormat
    @State private var formatter: CheatFormatter
    @State private var code: String
    @State private var enabled: Bool = true
    @State private var isCodeValid: Bool = false

    init(target: EditorTarget<CheatObject>, game: GameObject, cheatFormats: [CoreCheatFormat]) {
        self.game = game
        self.cheatFormats = cheatFormats
        self.target = target
        
        var format: CoreCheatFormat
        switch target {
        case .create:
            self.title = "ADD_CHEAT"
            
            format = cheatFormats[0]
            self.label = ""
            self.code = ""
        case .edit(let cheat):
            self.title = "EDIT_CHEAT"
            
            format = cheatFormats.first { $0.id == cheat.type }!
            self.label = cheat.label ?? ""
            self.code = cheat.code ?? ""
            self.enabled = cheat.enabled
        }
        
        self.format = cheatFormats[0]
        self.formatter = format.makeFormatter()
        self.isCodeValid = formatter.validate(value: code)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("CHEAT_NAME", text: $label)
                    Toggle("CHEAT_ENABLED", isOn: $enabled)
                } header: {
#if !os(macOS)
                    Text("CHEAT_NAME_AND_STATE")
#endif
                }

                Section {
                    Picker("CHEAT_FORMAT", selection: $format) {
                        ForEach(cheatFormats, id: \.id) { format in
							Text(format.name).tag(format)
                        }
                    }

#if os(macOS)
                    LabeledContent("CHEAT_CODE") {
                        CheatCodeField(value: $code, formatter: $formatter)
                    }
#else
                    CheatCodeField(value: $code, formatter: $formatter)
#endif
                } header: {
#if !os(macOS)
                    Text("CHEAT_CODE")
#endif
                } footer: {
					Text("CHEAT_CORE_FORMAT_MESSAGE \"\(format.pattern.uppercased())\"")
                }
            }
            .formStyle(.grouped)
            .onChange(of: format, perform: formatChanged)
            .onChange(of: code, perform: codeChanged)
            .navigationTitle(title)
#if os(macOS)
            .padding()
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton(action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    ConfirmButton("DONE", action: save)
                        .disabled(label.isEmpty || !isCodeValid)
                }
            }
        }
    }

    private func formatChanged(value: CoreCheatFormat) {
        self.formatter = value.makeFormatter()
        self.code = formatter.formatInput(value: code)
        self.isCodeValid = formatter.validate(value: code)
    }

    private func codeChanged(value: String) {
        self.isCodeValid = formatter.validate(value: value)
    }

    private func save() {
        guard isCodeValid && !label.isEmpty else { return }

        let format = self.format.id
        let normalizedCode = self.format.normalizeCode(string: self.code)

        Task {
            do {
                switch target {
                case .create:
                    try await persistence.objects.createCheat(
                        name: self.label,
                        code: normalizedCode,
                        format: format,
                        isEnabled: self.enabled,
                        for: .init(self.game)
                    )
                case .edit(let cheat):
                    try await persistence.objects.update(
                        cheat: .init(cheat),
                        name: self.label,
                        code: self.format.normalizeCode(string: self.code),
                        format: self.format.id,
                        enabled: self.enabled
                    )
                }
                self.dismiss()
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        NavigationStack {
            CheatEditorView(target: .create, game: game, cheatFormats: [])
        }
    }
}
