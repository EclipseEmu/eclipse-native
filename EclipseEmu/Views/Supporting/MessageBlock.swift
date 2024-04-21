//
//  MessageBlock.swift
//  EclipseEmu
//
//  Created by Tucker Morley on 2024.04.20.
//

import SwiftUI

struct MessageBlock<Content: View>: View {
    var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack {
            self.content()
        }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .modify {
                #if canImport(UIKit)
                if #available(iOS 17.0, macOS 14.0, *) {
                    $0.background(.background.secondary)
                } else {
                    $0.background(Color(uiColor: .secondarySystemBackground))
                }
                #else
                if #available(macOS 14.0, *) {
                    $0.background(Color(nsColor: .tertiarySystemFill))
                } else {
                    $0.background(Color(nsColor: .gridColor))
                }
                #endif
            }
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

#Preview {
    MessageBlock {
        Text("Lorem ipsum")
    }
}
