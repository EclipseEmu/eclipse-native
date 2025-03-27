import EclipseKit
import SwiftUI

struct CheatCodeField {
    @Binding var value: String
    @Binding var formatter: CheatFormatter

    func makeCoordinator() -> Coordinator {
        Coordinator(value: self.$value, formatter: self.$formatter)
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

// MARK: Formatter

final class CheatFormatter {
    struct FormattedText {
        static let zero = Self(formattedText: "", cursorOffset: 0)

        let formattedText: String
        let cursorOffset: Int
    }

    private let formatString: String
    private let characterSet: CharacterSet

    init(format: UnsafePointer<CChar>, characterSet: CharacterSet) {
        self.formatString = String(cString: format)
        self.characterSet = characterSet
    }

    @inlinable
    func formatInput(value: String) -> String {
        return formatInput(
            value: value,
            range: value.startIndex ..< value.startIndex,
            wasBackspace: false,
            insertion: ""
        ).formattedText
    }

    func formatInput(
        value: String,
        range: Range<String.Index>,
        wasBackspace: Bool,
        insertion: String
    ) -> FormattedText {
        let isBackspace = Int(wasBackspace)
        let isNotBackspace = isBackspace ^ 1
        let cursorIndex = range.lowerBound

        var output = ""
        var offset = insertion.countValidCharacters(in: characterSet)
        var valueIndex = value.startIndex
        var formatIndex = formatString.startIndex

        var wasLastCharAutomaticallyInserted = 0
        while valueIndex < value.endIndex {
            let isCursorHere = Int(cursorIndex == valueIndex)
            let shouldBumpOffset = isCursorHere & isNotBackspace
            offset -= (isNotBackspace ^ 1) & wasLastCharAutomaticallyInserted & isCursorHere

            if formatIndex == formatString.endIndex {
                formatIndex = formatString.startIndex
                output.append("\n" as Character)
                offset += shouldBumpOffset
            }

            if formatString[formatIndex] != "x" {
                output.append(formatString[formatIndex])
                offset += shouldBumpOffset
                wasLastCharAutomaticallyInserted = 1
            } else {
                let char = value[valueIndex]
                valueIndex = value.index(after: valueIndex)
                guard characterSet.contains(character: char) else { continue }
                output.append(char.uppercased())
                wasLastCharAutomaticallyInserted = 0
            }

            formatIndex = formatString.index(after: formatIndex)
        }

        let isCursorHere = Int(cursorIndex == valueIndex)
        offset -= isCursorHere & isBackspace & wasLastCharAutomaticallyInserted

        let newPosition = cursorIndex.utf16Offset(in: output) + offset
        let newIndex = if newPosition > output.utf16.count {
            output.index(before: output.endIndex)
        } else if newPosition < 0 {
            output.startIndex
        } else {
            output.index(cursorIndex, offsetBy: offset)
        }

        return FormattedText(
            formattedText: output,
            cursorOffset: newIndex.utf16Offset(in: output)
        )
    }

    func validate(value: String) -> Bool {
        guard !value.isEmpty else { return false }

        var splitIterator = LazySplitIterator(value, seperator: "\n")
        while let line = splitIterator.next() {
            guard line.count == formatString.count else { return false }

            var formatIndex = formatString.startIndex
            var lineIndex = line.startIndex
            while formatIndex < formatString.endIndex {
                let char = line[lineIndex]
                let formatCh = formatString[formatIndex]
                let isPlaceholder = formatCh == "x"
                if isPlaceholder && !characterSet.contains(character: char) || !isPlaceholder && char != formatCh {
                    return false
                }

                formatIndex = formatString.index(after: formatIndex)
                lineIndex = line.index(after: lineIndex)
            }
        }

        return true
    }
}
