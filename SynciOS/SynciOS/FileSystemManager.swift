//
//  FileSystemManager.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//
import Foundation

enum FileSystemManagerError: Error {
    case fileExists
    case noFileFound
    case failedToParseObject
    case fileEmpty
}

protocol FileSystemProviding {
    func allFileNames() throws -> [String]
    func parseJSONFile(name: String) throws -> [String: Any]
    func readFile(name: String) throws -> Data
    func writeFile(name: String, data: Data) throws
    func createFile(name: String, data: Data) throws
    func deleteFile(name: String) throws
    func fileExists(name: String) -> Bool
}

final class FileSystemManager {
    private let folderURL: URL
    
    init(folderURL: URL) throws {
        self.folderURL = folderURL
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
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
    
    func createFile(name: String, data: Data) throws {
        let filePath = folderURL.path + "/" + name
        guard !FileManager.default.fileExists(atPath: filePath) else { throw FileSystemManagerError.fileExists }
        try (data as NSData).write(toFile: filePath)
    }
    
    func readFile(name: String) throws -> Data {
        let filePath = folderURL.path + "/" + name
        return try NSData(contentsOfFile: filePath) as Data
    }
    
    func writeFile(name: String, data: Data) throws {
        let filePath = folderURL.path + "/" + name
        try (data as NSData).write(toFile: filePath)
    }
    
    func deleteFile(name: String) throws {
        let filePath = folderURL.path + "/" + name
        try FileManager.default.removeItem(atPath: filePath)
    }
    
    func fileExists(name: String) -> Bool {
        // TODO: extract in func
        let filePath = folderURL.path + "/" + name
        return FileManager.default.fileExists(atPath: filePath)
    }
}
