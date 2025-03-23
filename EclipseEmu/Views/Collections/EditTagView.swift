import SwiftUI

private struct ColorPickerView: View {
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
                        let isSelected = self.selectedColor == color
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

struct EditTagView: View {
    @EnvironmentObject var persistence: Persistence
    @Environment(\.dismiss) var dismiss
    @State var name: String
    @State var color: Color

    var tag: Tag?

    init(tag: Tag? = nil) {
        self.tag = tag
        if let tag {
            self.name = tag.name ?? ""
            self.color = tag.parsedColor.color
        } else {
            self.name = ""
            self.color = .blue
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section {
                        VStack {
                            Image(systemName: "tag")
                                .font(.system(size: 42.0))
                                .fixedSize()
                                .aspectRatio(1.0, contentMode: .fit)
                                .frame(width: 64.0, height: 64.0)
                                .foregroundStyle(.white)
                                .padding()
                                .background(color)
                                .clipShape(Circle())
                                .padding()

                            TextField("Tag Name", text: self.$name)
                                .padding()
                                .multilineTextAlignment(.center)
                                .background(.quaternary.opacity(0.45))
                                .font(.headline)
                                .clipShape(RoundedRectangle(cornerRadius: 12.0))
                        }
                    }

                    Section {
                        ColorPickerView(selectedColor: self.$color)
                    }
                }
            }
            .navigationTitle(self.tag == nil ? "New Tag" : "Edit Tag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        self.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: self.upsert) {
                        Text(self.tag == nil ? "Create" : "Save")
                    }
                    .disabled(self.name.isEmpty)
                }
            }
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    func upsert() {
        guard !self.name.isEmpty else { return }

        let color = TagColor(color: self.color)
        Task {
            do {
                if let tag {
                    try await persistence.objects.update(
                        tag: .init(tag),
                        name: self.name,
                        color: color
                    )
                } else {
                    try await persistence.objects.createTag(name: self.name, color: color)
                }

                self.dismiss()
            } catch {
                // FIXME: Surface error
                print(error)
            }

        }
    }
}

#Preview("Create") {
    EditTagView()
}

@available(iOS 18.0, macOS 15.0, *)
#Preview("Edit", traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Tag.fetchRequest()) { tag, _ in
        NavigationStack {
            EditTagView(tag: tag)
        }
    }
}
