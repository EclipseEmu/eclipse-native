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
    @State var code: String = ""
    @State var enabled: Bool = true

    init(cheat: Cheat?, game: Game, cheatFormats: UnsafeBufferPointer<GameCoreCheatFormat>) {
        self.cheat = cheat
        self.game = game
        self.cheatFormats = cheatFormats
        self.isCreatingCheat = cheat == nil
        
        if let cheat {
            self.format = cheatFormats.first { String(cString: $0.id) == cheat.type }!
            self.label = cheat.label ?? ""
            self.code = cheat.code ?? ""
            self.enabled = cheat.enabled
        } else {
            self.format = cheatFormats[0]
        }
    }

    var body: some View {
        CompatNavigationStack {
            Form {
                Section {
                    TextField("Name", text: $label)
                    
                    Toggle("Enabled", isOn: $enabled)
                    
                    Picker("Format", selection: $format) {
                        ForEach(self.cheatFormats, id: \.id) { format in
                            Text(String(cString: format.displayName)).tag(format)
                        }
                    }
                } header: {
                    Text("Name")
                }
                
                Section {
                    CheatCodeField(value: $code, format: format)
                } header: {
                    Text("Code")
                } footer: {
                    Text("The code will automatically be formatted as \"\(String(cString: self.format.format).uppercased())\"")
                }
            }
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
