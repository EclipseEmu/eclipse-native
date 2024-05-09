import SwiftUI
import EclipseKit
import mGBAEclipseCore

struct CheatCodeField {
    @Binding var value: String
    var format: GameCoreCheatFormat
}

#if canImport(UIKit)
extension CheatCodeField: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.autocorrectionType = .no
        textView.font = .monospacedSystemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.text = self.value
        textView.delegate = context.coordinator
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CheatCodeField
        var formatter: GameCoreCheatFormat.Formatter
        
        init(_ parent: CheatCodeField) {
            self.parent = parent
            self.formatter = self.parent.format.makeFormatter()
            
            super.init()
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
            guard 
                let text = textView.text,
                let swiftRange = Range(range, in: text)
            else { return false }
            
            let wasBackspace = if 
                let char = string.cString(using: .utf8),
                strcmp(char, "\\b") == -92
            {
                true
            } else {
                false
            }
            
            let newString = (text as NSString).replacingCharacters(in: range, with: string)
            let result = self.formatter.formatInput(
                value: newString,
                range: swiftRange,
                wasBackspace: wasBackspace,
                insertionCount: string.countValidCharacters(in: self.formatter.characterSet)
            )
            
            textView.text = result.formattedText
            self.parent.value = result.formattedText

            if let newPosition = textView.position(from: textView.beginningOfDocument, offset: result.cursorOffset) {
                let newSelectedRange = textView.textRange(from: newPosition, to: newPosition)
                textView.selectedTextRange = newSelectedRange
            }

            return false
        }
    }
}
#else
extension CheatCodeField: NSViewRepresentable {
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.string = self.value
        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: NSFont.labelFontSize, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        
        return textView
    }
    
    func updateNSView(_ nsView: NSTextView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CheatCodeField
        var formatter: GameCoreCheatFormat.Formatter
        
        init(_ parent: CheatCodeField) {
            self.parent = parent
            self.formatter = self.parent.format.makeFormatter()
            super.init()
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString string: String?) -> Bool {
            guard let string else { print(range); return false }
            
            let text = textView.string
            guard let swiftRange = Range(range, in: text) else { return false }
            
            let wasBackspace = if
                let char = string.cString(using: .utf8),
                strcmp(char, "\\b") == -92
            {
                true
            } else {
                false
            }
            
            let newString = text.replacingCharacters(in: swiftRange, with: string)
            let result = self.formatter.formatInput(
                value: newString,
                range: swiftRange,
                wasBackspace: wasBackspace,
                insertionCount: string.countValidCharacters(in: self.formatter.characterSet)
            )
            
            textView.string = result.formattedText
            self.parent.value = result.formattedText
            
            let newSelectedRange = NSRange(location: result.cursorOffset, length: 0)
            textView.setSelectedRange(newSelectedRange)

            return false
        }
    }
}
#endif

#Preview {
    var code = ""
    return Form {
        Section {
            CheatCodeField(
                value: .init(get: { code }, set: { code = $0 }),
                format: mGBAEclipseCore.coreInfo.cheatFormats.pointee
            )
        } header: {
            Text("Code")
        }
    }
}
