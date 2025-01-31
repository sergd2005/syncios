//
//  FileSystemManager.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//
import Foundation

enum FileSystemManagerError: Error {
    case fileExists
    case failedToParseObject
    case fileEmpty
}

protocol FileSystemProviding {
    func allFileNames() throws -> [String]
    func parseJSONFile(name: String) throws -> [String: Any]
    func writeFile(name: String, data: [String: Any]) throws
    func createFile(name: String, data: [String: Any]) throws
}

final class FileSystemManager {
    private let folderURL: URL
    
    init(folderURL: URL) {
        self.folderURL = folderURL
    }
}

extension FileSystemManager: FileSystemProviding {
    func allFileNames() throws -> [String] {
        guard let dirEnum = FileManager.default.enumerator(atPath: folderURL.path) else {
            return []
        }
        var result = [String]()
        while let file = dirEnum.nextObject() as? String {
            if file.hasSuffix(".json") {
                result.append(file)
            }
        }
        return result
    }
    
    func parseJSONFile(name: String) throws -> [String: Any] {
        guard let result = try JSONSerialization.jsonObject(with: try NSData(contentsOfFile: folderURL.path + "/" + name) as Data) as? [String: Any]
        else {
            throw FileSystemManagerError.failedToParseObject
        }
        guard !result.isEmpty else { throw FileSystemManagerError.fileEmpty }
        return result
    }
    
    func createFile(name: String, data: [String: Any]) throws {
        let filePath = folderURL.path + "/" + name + ".json"
        guard !FileManager.default.fileExists(atPath: filePath) else { throw FileSystemManagerError.fileExists }
        try (JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) as NSData).write(toFile: filePath)
    }
    
    func writeFile(name: String, data: [String: Any]) throws {
        let filePath = folderURL.path + "/" + name + ".json"
        try (JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) as NSData).write(toFile: filePath)
    }
}
