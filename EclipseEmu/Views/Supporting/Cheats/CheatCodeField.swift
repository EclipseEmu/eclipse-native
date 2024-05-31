import SwiftUI
import EclipseKit

struct CheatCodeField {
    @Binding var value: String
    @Binding var formatter: CheatFormatter

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, formatter: $formatter)
    }

    class Coordinator: NSObject {
        var value: Binding<String>
        var formatter: Binding<CheatFormatter>

        init(value: Binding<String>, formatter: Binding<CheatFormatter>) {
            self.value = value
            self.formatter = formatter
            super.init()
        }
    }
}

#if canImport(UIKit)
extension CheatCodeField: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.font = .monospacedSystemFont(ofSize: UIFont.labelFontSize, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.text = self.formatter.formatInput(value: self.value)
        textView.delegate = context.coordinator

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != self.value {
            uiView.text = self.value
        }
    }
}

extension CheatCodeField.Coordinator: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
        guard
            let text = textView.text,
            let swiftRange = Range(range, in: text)
        else { return false }

        let newString = text.replacingCharacters(in: swiftRange, with: string)
        let result = self.formatter.wrappedValue.formatInput(
            value: newString,
            range: swiftRange,
            wasBackspace: string.isEmpty,
            insertion: string
        )

        textView.text = result.formattedText

        if let newPosition = textView.position(from: textView.beginningOfDocument, offset: result.cursorOffset) {
            let newSelectedRange = textView.textRange(from: newPosition, to: newPosition)
            textView.selectedTextRange = newSelectedRange
        }

        self.value.wrappedValue = result.formattedText

        return false
    }
}
#else
extension CheatCodeField: NSViewRepresentable {
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.string = self.formatter.formatInput(value: self.value)
        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: NSFont.labelFontSize, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear

        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.string != self.value {
            nsView.string = self.value
        }
    }
}

extension CheatCodeField.Coordinator: NSTextViewDelegate {
    func textView(
        _ textView: NSTextView,
        shouldChangeTextIn range: NSRange,
        replacementString string: String?
    ) -> Bool {
        guard let string else { return false }

        let text = textView.string
        guard let swiftRange = Range(range, in: text) else { return false }

        let newString = text.replacingCharacters(in: swiftRange, with: string)
        let result = self.formatter.wrappedValue.formatInput(
            value: newString,
            range: swiftRange,
            wasBackspace: string.isEmpty,
            insertion: string
        )

        textView.string = result.formattedText
        self.value.wrappedValue = result.formattedText

        let newSelectedRange = NSRange(location: result.cursorOffset, length: 0)
        textView.setSelectedRange(newSelectedRange)

        return false
    }
}
#endif
