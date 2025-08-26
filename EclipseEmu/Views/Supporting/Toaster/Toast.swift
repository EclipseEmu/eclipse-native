import SwiftUI

struct Toast: Identifiable, Equatable {
    let id = RuntimeUID()
    let image: Image
    let message: LocalizedStringKey
    
    init(image: Image, message: LocalizedStringKey) {
        self.image = image
        self.message = message
    }
    
    init(_ message: LocalizedStringKey, systemImage: String) {
        self.image = Image(systemName: systemImage)
        self.message = message
    }
}
