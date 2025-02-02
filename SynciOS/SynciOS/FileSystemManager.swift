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
    case failedToCreateFile
}

protocol FileSystemProviding {
    func allFileNames() throws -> [String]
    func readFile(name: String) throws -> Data
    func writeFile(name: String, data: Data) throws
    func createFile(name: String, data: Data?) throws
    func deleteFile(name: String) throws
    func fileExists(name: String) -> Bool
    func getModifiedDate(name: String) throws -> Date?
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
    
    func createFile(name: String, data: Data?) throws {
        let filePath = fullPath(for: name)
        guard !FileManager.default.fileExists(atPath: filePath) else { throw FileSystemManagerError.fileExists }
        guard FileManager.default.createFile(atPath: filePath, contents: data) else { throw FileSystemManagerError.failedToCreateFile }
    }
    
    func readFile(name: String) throws -> Data {
        return try NSData(contentsOfFile: fullPath(for: name)) as Data
    }
    
    func writeFile(name: String, data: Data) throws {
        try (data as NSData).write(toFile: fullPath(for: name))
    }
    
    func deleteFile(name: String) throws {
        try FileManager.default.removeItem(atPath: fullPath(for: name))
    }
    
    func fileExists(name: String) -> Bool {
        FileManager.default.fileExists(atPath: fullPath(for: name))
    }
    
    func getModifiedDate(name: String) throws -> Date? {
        try FileManager.default.attributesOfItem(atPath: fullPath(for: name))[FileAttributeKey.modificationDate] as? Date
    }
}

// MARK: Private API
extension FileSystemManager {
    private func fullPath(for name: String) -> String {
        folderURL.path + "/" + name
    }
}
