import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

//final class ImageStorage {
//    #if canImport(AppKit)
//    typealias Value = NSImage
//    #elseif canImport(UIKit)
//    typealias Value = UIImage
//    #endif
//    
//    enum Failure: LocalizedError {
//        case failedToGetImageData
//        case failedToLoadImageData
//        case failedToCreateFile
//    }
//    
//    private let fileManager: FileManager
//    private let directory: URL
//    
//    init(directoryName: String, fileManager: FileManager = .default) {
//        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(directoryName, isDirectory: true)
//        self.fileManager = fileManager
//        self.directory = directory
//        
//        if !fileManager.fileExists(atPath: directory.path) {
//            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
//        }
//    }
//    
//    func getUrl(for id: String) -> URL {
//        self.directory.appendingPathComponent(id)
//    }
//    
//    func set(id: String, value: Value) throws {
//        guard let data = value.jpegData(compressionQuality: 1.0) else {
//            throw Failure.failedToGetImageData
//        }
//        guard fileManager.createFile(atPath: getUrl(for: id).path, contents: data, attributes: nil) else {
//            throw Failure.failedToCreateFile
//        }
//    }
//    
//    func get(id: String) throws -> Value {
//        let data = try Data(contentsOf: getUrl(for: id))
//        guard let image = Self.Value(data: data) else {
//            throw Failure.failedToLoadImageData
//        }
//        return image
//    }
//}
