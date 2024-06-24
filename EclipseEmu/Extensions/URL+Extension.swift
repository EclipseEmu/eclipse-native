import Foundation

extension URL {
    func fileName() -> String {
        let fileName = self.lastPathComponent
        return if let fileExtensionIndex = fileName.firstIndex(of: ".") {
            String(fileName[fileName.startIndex ..< fileExtensionIndex])
        } else {
            fileName
        }
    }

    func fileExtension() -> String? {
        let fileName = self.lastPathComponent
        return if let fileExtensionIndex = fileName.firstIndex(of: ".") {
            String(fileName[fileExtensionIndex...])
        } else {
            nil
        }
    }

    func fileNameAndExtension() -> (String, String?) {
        let fileName = self.lastPathComponent
        return if let fileExtensionIndex = fileName.firstIndex(of: ".") {
            (
                String(fileName[fileName.startIndex ..< fileExtensionIndex]),
                String(fileName[fileExtensionIndex...])
            )
        } else {
            (fileName, nil)
        }
    }
}
