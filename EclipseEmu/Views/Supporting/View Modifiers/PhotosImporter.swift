import PhotosUI
import SwiftUI

enum PhotosImporterFailure: LocalizedError {
    case failedToObtainUrl
}

#if canImport(UIKit)
fileprivate struct PhotosImporterSheet: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var onSelection: (Result<URL, any Error>) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator

        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: PhotosImporterSheet

        init(_ parent: PhotosImporterSheet) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let result: Result<URL, any Error> = if
            let url = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                .success(url)
            } else {
                .failure(PhotosImporterFailure.failedToObtainUrl)
            }

            parent.onSelection(result)
            parent.dismiss()
        }
    }
}
#endif

struct PhotosImporterModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onSelection: (Result<URL, any Error>) -> Void

    func body(content: Content) -> some View {
        content
        #if canImport(UIKit)
        .sheet(isPresented: $isPresented) {
            PhotosImporterSheet(onSelection: onSelection)
        }
        #elseif canImport(AppKit)
        .onChange(of: isPresented) {
            guard isPresented else { return }
            Task {
                await self.openPicker()
            }
        }
        #endif
    }

    #if canImport(AppKit)
    func openPicker() async {
        do {
            let url = try await MainActor.run(resultType: Optional<URL>.self) {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.png, .jpeg]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false

                let response = panel.runModal()

                guard response != .cancel else {
                    return nil
                }

                guard response == .OK, let url = panel.url else {
                    throw PhotosImporterFailure.failedToObtainUrl
                }

                return url
            }

            guard let url else { return }

            onSelection(.success(url))
        } catch {
            onSelection(.failure(error))
        }
    }
    #endif
}

extension View {
    func photosImporter(
        isPresented: Binding<Bool>,
        onSelection: @escaping (Result<URL, any Error>) -> Void
    ) -> some View {
        modifier(PhotosImporterModifier(
            isPresented: isPresented,
            onSelection: onSelection
        ))
    }
}

#Preview {
    struct PreviewView: View {
        @State var result: Result<URL, any Error>?
        @State var isPickerOpen: Bool = false

        var body: some View {
            switch result {
            case .success(let image):
                AsyncImage(url: image) { imagePhase in
                    switch imagePhase {
                    case .empty:
                        EmptyView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fit)
                    case .failure(let error):
                        Text(error.localizedDescription)
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding()
            case .failure(let error):
                Text(error.localizedDescription)
            case .none:
                EmptyView()
            }

            Button("Pick Image", systemImage: "photo") {
                self.isPickerOpen = true
            }
            .photosImporter(isPresented: $isPickerOpen) { result in
                self.result = result
            }
        }
    }

    return PreviewView()
}
