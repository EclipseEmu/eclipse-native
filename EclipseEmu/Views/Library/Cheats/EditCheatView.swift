import EclipseKit
import SwiftUI

struct EditCheatView: View {
    private let game: Game
    private let cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>
    private let cheat: Cheat?
    private let isCreatingCheat: Bool

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: Persistence
    @State var label: String
    @State var format: GameCoreCheatFormat
    @State var formatter: CheatFormatter
    @State var code: String
    @State var enabled: Bool = true
    @State var isCodeValid: Bool = false

    init(cheat: Cheat?, game: Game, cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>) {
        self.cheat = cheat
        self.game = game
        self.cheatFormats = cheatFormats
        self.isCreatingCheat = cheat == nil

        if let cheat {
            let format = cheatFormats.first { String(cString: $0.id) == cheat.type }!
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
                    TextField("Name", text: self.$label)
                    Toggle("Enabled", isOn: self.$enabled)
                } header: {
#if !os(macOS)
                    Text("Name & State")
#endif
                }

                Section {
                    Picker("Format", selection: self.$format) {
                        ForEach(self.cheatFormats, id: \.id) { format in
                            Text(String(cString: format.displayName)).tag(format)
                        }
                    }

#if os(macOS)
                    LabeledContent("Code") {
                        CheatCodeField(value: self.$code, formatter: self.$formatter)
                    }
#else
                    CheatCodeField(value: self.$code, formatter: self.$formatter)
#endif
                } header: {
#if !os(macOS)
                    Text("Code")
#endif
                } footer: {
                    Text("The code will automatically be formatted as \"\(String(cString: self.format.format).uppercased())\"")
                }
            }
            .onChange(of: self.format, perform: self.formatChanged)
            .onChange(of: self.code, perform: self.codeChanged)
            .navigationTitle(self.isCreatingCheat ? "Add Cheat" : "Edit Cheat")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#else
                .padding()
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            self.dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done", action: self.save)
                            .disabled(self.label.isEmpty || !self.isCodeValid)
                    }
                }
        }
    }

    func formatChanged(value: GameCoreCheatFormat) {
        self.formatter = value.makeFormatter()
        self.code = self.formatter.formatInput(value: self.code)
        self.isCodeValid = self.formatter.validate(value: self.code)
    }

    func codeChanged(value: String) {
        self.isCodeValid = self.formatter.validate(value: value)
    }

    func save() {
        guard self.isCodeValid && !self.label.isEmpty else { return }

        let format = String(cString: self.format.id)
        let normalizedCode = self.format.normalizeCode(string: self.code)

        Task {
            do {
                if let cheat {
                    try await persistence.objects.update(
                        cheat: .init(cheat),
                        name: self.label,
                        code: self.format.normalizeCode(string: self.code),
                        format: String(cString: self.format.id),
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
#Preview(traits: .modifier(PreviewStorage())) {
    let core = EclipseEmuApp.cores.allCores[0]
    let formats = UnsafeBufferPointer(start: core.cheatFormats, count: core.cheatFormatsCount)

    PreviewSingleObjectView(Game.fetchRequest()) { game, _ in
        NavigationStack {
            EditCheatView(cheat: nil, game: game, cheatFormats: formats)
        }
    }
}
