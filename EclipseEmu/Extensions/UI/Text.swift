import SwiftUI

extension Text {
    init(verbatim: String?, fallback: LocalizedStringKey) {
        if let verbatim {
            self.init(verbatim: verbatim)
        } else {
            self.init(fallback)
        }
    }

    init<F>(_ input: F.FormatInput?, format: F, fallback: LocalizedStringKey)
        where F: FormatStyle, F.FormatInput: Equatable, F.FormatOutput == String {
            if let input {
                self.init(input, format: format)
            } else {
                self.init(fallback)
            }
        }
}
