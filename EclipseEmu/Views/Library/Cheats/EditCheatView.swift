import SwiftUI
import EclipseKit

struct EditCheatView: View {
    var game: Game
    var cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>
    var cheat: Cheat?
    var isCreatingCheat: Bool
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.persistenceCoordinator) var persistence
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
        CompatNavigationStack {
            Form {
                Section {
                    TextField("Name", text: $label)
                    Toggle("Enabled", isOn: $enabled)
                } header: {
                    #if !os(macOS)
                    Text("Name & State")
                    #endif
                }
                
                Section {
                    Picker("Format", selection: $format) {
                        ForEach(self.cheatFormats, id: \.id) { format in
                            Text(String(cString: format.displayName)).tag(format)
                        }
                    }
                    
                    #if os(macOS)
                    LabeledContent("Code") {
                        CheatCodeField(value: $code, formatter: $formatter)
                    }
                    #else
                    CheatCodeField(value: $code, formatter: $formatter)
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
            .navigationTitle(isCreatingCheat ? "Add Cheat" : "Edit Cheat")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #else
            .padding()
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", action: self.save)
                        .disabled(label.isEmpty || !isCodeValid)
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

        if let cheat {
            cheat.type = String(cString: self.format.id)
            cheat.label = self.label
            cheat.code = self.format.normalizeCode(string: self.code)
            cheat.enabled = self.enabled
            CheatManager.update(cheat: cheat, in: persistence)
            
            dismiss()
        } else {
            do {
                try CheatManager.create(
                    name: self.label,
                    code: normalizedCode,
                    format: format,
                    isEnabled: self.enabled,
                    for: self.game,
                    in: persistence
                )
                dismiss()
            } catch {
                print(error)
            }
        }
    }
}

#if DEBUG
#Preview {
    let context = PersistenceCoordinator.preview.container.viewContext
    let game = Game(context: context)
    game.system = .gba
    
    let core = EclipseEmuApp.cores.allCores[0]
    let formats = UnsafeBufferPointer(start: core.cheatFormats, count: core.cheatFormatsCount)
    
    return EditCheatView(cheat: nil, game: game, cheatFormats: formats)
        .environment(\.managedObjectContext, context)
}
#endif
