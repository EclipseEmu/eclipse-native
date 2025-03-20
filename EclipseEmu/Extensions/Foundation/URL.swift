import Foundation

extension URL {
    func fileName() -> String {
        let fileName = self.lastPathComponent
        return if let dotIndex = fileName.lastIndex(of: ".") {
            String(fileName[fileName.startIndex ..< dotIndex])
        } else {
            fileName
        }
    }

    func fileExtension() -> String? {
        let fileName = self.lastPathComponent
        return if let dotIndex = fileName.lastIndex(of: ".") {
            String(fileName[dotIndex...])
        } else {
            nil
        }
    }

    func fileNameAndExtension() -> (String, String?) {
        let fileName = self.lastPathComponent
        return if let dotIndex = fileName.lastIndex(of: ".") {
            (String(fileName[fileName.startIndex ..< dotIndex]), String(fileName[dotIndex...]))
        } else {
            (fileName, nil)
        }
    }
}
