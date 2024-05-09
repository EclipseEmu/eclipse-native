import SwiftUI
import EclipseKit

struct EditCheatView: View {
    var game: Game
    var cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>
    var cheat: Cheat?
    var isCreatingCheat: Bool
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @State var label: String = ""
    @State var format: GameCoreCheatFormat 
    @State var formatter: GameCoreCheatFormat.Formatter
    @State var code: String = ""
    @State var enabled: Bool = true
    @State var isValid: Bool = false

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
            self.isValid = false
        } else {
            let format = cheatFormats[0]
            self.format = cheatFormats[0]
            self.formatter = format.makeFormatter()
        }
    }

    var body: some View {
        CompatNavigationStack {
            Form {
                Section {
                    TextField("Name", text: $label)
                    
                    
                    Picker("Format", selection: $format) {
                        ForEach(self.cheatFormats, id: \.id) { format in
                            Text(String(cString: format.displayName)).tag(format)
                        }
                    }
                    .onChange(of: format, perform: { value in
                        self.formatter = value.makeFormatter()
                    })
                    Toggle("Enabled", isOn: $enabled)
                } header: {
                    #if !os(macOS)
                    Text("Name")
                    #endif
                }
                
                Section {
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
            #if os(macOS)
            .padding()
            #endif
            .navigationTitle(isCreatingCheat ? "Add Cheat" : "Edit Cheat")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DismissButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // FIXME: Validate
                        let cheatToEdit = if let cheat {
                            cheat
                        } else {
                            Cheat(context: viewContext)
                        }
                        
                        cheatToEdit.type = String(cString: self.format.id)
                        cheatToEdit.label = self.label
                        cheatToEdit.code = self.format.normalizeCode(string: self.code)
                        cheatToEdit.enabled = self.enabled
                        cheatToEdit.game = self.game
                        
                        do {
                            try viewContext.save()
                        } catch {
                            print(error)
                        }
                        dismiss()
                    } label: {
                        Text(isCreatingCheat ? "Add" : "Save")
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let game = Game(context: context)
    game.system = .gba
    
    let core = EclipseEmuApp.cores.allCores[0]
    let formats = UnsafeBufferPointer(start: core.cheatFormats, count: core.cheatFormatsCount)
    
    return EditCheatView(cheat: nil, game: game, cheatFormats: formats)
        .environment(\.managedObjectContext, context)
}
