import SwiftUI

struct CollectionColorPickerView: View {
    static let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown
    ]

    @Binding var selectedColor: Color

    var body: some View {
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
}

struct CollectionIconPickerView: View {
    static let icons: [String] = [
        "list.bullet", "gamecontroller.fill", "tv.fill", "questionmark.app.fill", "backpack.fill", "pills.fill",
        "tent.fill", "shippingbox.fill",
        "car.fill", "sailboat.fill", "tram.fill",
        "square.fill", "circle.fill", "triangle.fill", "diamond.fill", "heart.fill", "star.fill"
    ]

    @Binding var selectedIcon: GameCollection.Icon

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 42, maximum: 64))]) {
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

struct EditCollectionView: View {
    @Environment(\.persistenceCoordinator) var persistence
    @Environment(\.dismiss) var dismiss
    @Environment(\.self) var environment
    @State var name: String

    @State var selectedColor: Color
    @State var selectedIcon: GameCollection.Icon

    var collection: GameCollection?

    init(collection: GameCollection? = nil) {
        self.collection = collection
        if let collection {
            self.name = collection.name ?? ""
            self.selectedIcon = collection.icon
            self.selectedColor = collection.parsedColor.color
        } else {
            self.name = ""
            self.selectedColor = .blue
            self.selectedIcon = .symbol("list.bullet")
        }
    }

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
                        CollectionColorPickerView(selectedColor: $selectedColor)
                    }

                    Section {
                        CollectionIconPickerView(selectedIcon: $selectedIcon)
                    }
                }
            }
            .navigationTitle(self.collection == nil ? "New Collection" : "Edit Collection")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: self.upsert) {
                        Text(self.collection == nil ? "Create" : "Save")
                    }
                    .disabled(self.name.isEmpty)
                }
            }
        }
    }

    func upsert() {
        guard !self.name.isEmpty else { return }

        let color = GameCollection.Color(color: self.selectedColor)
        if let collection {
            CollectionManager.update(
                collection,
                name: self.name,
                icon: self.selectedIcon,
                color: color,
                in: self.persistence
            )
        } else {
            CollectionManager.create(name: self.name, icon: self.selectedIcon, color: color, in: self.persistence)
        }

        self.dismiss()
    }
}

#Preview("Create") {
    EditCollectionView()
}

#Preview("Edit") {
    let persistence = PersistenceCoordinator.preview
    let collection = GameCollection(context: persistence.context)
    collection.name = "Hello"
    collection.color = GameCollection.Color.indigo.rawValue
    collection.icon = .symbol("heart.fill")

    return EditCollectionView(collection: collection)
        .environment(\.managedObjectContext, persistence.context)
        .environment(\.persistenceCoordinator, persistence)
}
