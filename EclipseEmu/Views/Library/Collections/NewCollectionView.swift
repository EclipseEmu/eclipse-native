import SwiftUI

struct NewCollectionView: View {
    @Environment(\.persistenceCoordinator) var persistence
    @Environment(\.dismiss) var dismiss
    @Environment(\.self) var environment
    @State var name: String = ""
//    @State var emoji: String = ""
//    @FocusState var isEmojiPickerSelected
    
    @State var selectedColor: Color = .blue
    @State var selectedIcon: GameCollection.Icon = .symbol("list.bullet")
    static let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown]
    static let icons: [String] = [
        "list.bullet", "gamecontroller.fill", "tv.fill", "questionmark.app.fill", "backpack.fill", "pills.fill",
        "tent.fill", "shippingbox.fill",
        "car.fill", "sailboat.fill", "tram.fill",
        "square.fill", "circle.fill", "triangle.fill", "diamond.fill", "heart.fill", "star.fill"
    ]
    
    var body: some View {
        CompatNavigationStack {
            ZStack {
                Form {
                    Section {
                        VStack {
                            CollectionIconView(icon: self.selectedIcon)
                                .font(.system(size: 42.0))
                                .fixedSize()
                                .aspectRatio(1.0, contentMode: .fit)
                                .frame(width: 64.0, height: 64.0)
                                .foregroundStyle(.white)
                                .padding()
                                .backgroundGradient(color: self.selectedColor)
                                .clipShape(Circle())
                                .padding()

                            TextField("Collection Name", text: $name)
                                .padding()
                                .multilineTextAlignment(.center)
                                .background(.quaternary.opacity(0.45))
                                .font(.headline)
                                .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        }
                    }
                    
                    Section {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 38, maximum: 48), spacing: 16.0)]) {
                            ForEach(Self.colors, id: \.self) { color in
                                Button {
                                    self.selectedColor = color
                                } label: {
                                    ZStack {
                                        let isSelected = selectedColor == color
                                        Circle()
                                            .foregroundColor(color)
                                            .scaleEffect(isSelected ? 0.8 : 1.0)
                                        Circle()
                                            .stroke(lineWidth: 3)
                                            .foregroundStyle(.tint)
                                            .opacity(isSelected ? 1.0 : 0)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Section {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 42, maximum: 64))]) {
//                            Circle()
//                                .modify {
//                                    if #available(iOS 17.0, *) {
//                                        $0.foregroundStyle(.background.secondary)
//                                    } else {
//                                        $0
//                                    }
//                                }
//                                .overlay {
//                                    ZStack {
//                                        CollectionIconView(icon: .symbol("face.smiling"))
//                                            .font(.system(size: 24.0))
//                                        if case .emoji(_) = selectedIcon {
//                                            Circle()
//                                                .stroke(lineWidth: 2)
//                                                .scaleEffect(1.1)
//                                        }
//                                    }
//                                    .foregroundStyle(.tint)
//                                }
//                                .onTapGesture {
//                                    self.isEmojiPickerSelected = true
//                                }
                            
                            ForEach(Self.icons, id: \.self) { image in
                                Button {
                                    self.selectedIcon = .symbol(image)
                                } label: {
                                    ZStack {
                                        let icon = GameCollection.Icon.symbol(image)
                                        let isSelected = selectedIcon == icon
                                        
                                        Circle()
                                            .fill(.quaternary.opacity(0.45))
                                        
                                        CollectionIconView(icon: icon)
                                            .font(.system(size: 18.0))
                                        
                                        Circle()
                                            .stroke(lineWidth: 3)
                                            .foregroundStyle(.tint)
                                            .opacity(isSelected ? 1.0 : 0)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DismissButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: self.create) {
                        Text("Create")
                    }
                    .disabled(self.name.isEmpty)
                }
            }
        }
    }
    
    func create() {
        guard !self.name.isEmpty else { return }
        
        let color = GameCollection.Color(color: self.selectedColor)
        CollectionManager.create(name: self.name, icon: self.selectedIcon, color: color, in: self.persistence)
        self.dismiss()
    }
}

#Preview {
    NewCollectionView()
}
