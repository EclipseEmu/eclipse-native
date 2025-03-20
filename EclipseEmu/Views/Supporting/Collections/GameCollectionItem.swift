import SwiftUI

struct GameCollectionItem: View {
    @EnvironmentObject var persistence: Persistence
    @ObservedObject var collection: Tag

    var body: some View {
        NavigationLink {
            GameCollectionView(collection: collection)
        } label: {
            VStack(alignment: .leading) {
                Image(systemName: "tag")
                    .aspectRatio(1.0, contentMode: .fit)
                    .fixedSize()
                    .frame(width: 32, height: 32)
                    .padding(.bottom, 8.0)

                Text(collection.name ?? "Unnamed Collection")
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .foregroundColor(.white)
            .padding()
            .background(collection.parsedColor.color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16.0))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                Task {
                    do {
                        try await persistence.library.delete(.init(collection))
                    } catch {
                        // FIXME: surface error
                        print(error)
                    }
                }
            } label: {
                Label("Delete Collection", systemImage: "trash")
            }
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .modifier(PreviewStorage())) {
    PreviewSingleObjectView(Tag.fetchRequest()) { tag, _ in
        NavigationStack {
            GameCollectionItem(collection: tag)
                .frame(width: 180.0)
        }
    }
}
