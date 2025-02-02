//
//  Editor.swift
//  SynciOS
//
//  Created by Sergii D on 2/1/25.
//

import Foundation

class SIFile {
    enum State {
        case none
        case created
        case opened
        case modified
        case saved
        case closed
        case deleted
    }
    
    fileprivate var fieldsStore: [String: Any] = [:]
    
    fileprivate let name: String
    
    fileprivate var storedFields: [String: SIFieldValue] = [:]
    
    fileprivate(set) var state: State = .none
    
    required init(name: String) {
        self.name = name
    }
    
    func fields() -> [String] {
        fatalError("function should be overriden")
    }
    
    func field<T>(for key: String) -> T? {
        storedFields[key]?.value as? T
    }
    
    func setField<T>(value: T?, for key: String) {
        storedFields[key]?.value = value
    }
    
    func toData(fieldsStore: [String: Any]) throws -> Data {
        fatalError("should be overriden")
    }
    
    func from(data: Data) throws -> [String: Any] {
        fatalError("should be overriden")
    }
}

extension SIFile: Equatable {
    static func == (lhs: SIFile, rhs: SIFile) -> Bool {
        lhs.name == rhs.name
    }
}

class SIFieldValue {
    fileprivate let key: String
    fileprivate weak var file: SIFile?

    fileprivate init(key: String, file: SIFile) {
        self.key = key
        self.file = file
    }
    
    fileprivate var value: Any? {
        get {
            file?.fieldsStore[key]
        }
        set {
            file?.state = .modified
            file?.fieldsStore[key] = newValue
        }
    }
}

protocol FileEditingProvider {
    func openFile<File: SIFile>(file: File) async throws -> File
    func openFile<File: SIFile>(name: String) async throws -> File
    func closeFile<File: SIFile>(_ file: File) async throws
    func readFile<File: SIFile>(_ file: File) async throws
    func saveFile<File: SIFile>(_ file: File) async throws
    func createFile<File: SIFile>(name: String) async throws -> File
    func deleteFile<File: SIFile>(_ file: File) async throws
}

enum FileEditorError: Error {
    case fileTypeMismatch
    case fileNotSaved
}

actor FileEditor: FileEditingProvider {
    private var files = [String: SIFile]()
    
    func openFile<File: SIFile>(file: File) async throws -> File {
        try await openFile(name: file.name)
    }
    
    func openFile<File: SIFile>(name: String) async throws -> File {
        if let existingFile = files[name] {
            guard let castedFile = existingFile as? File else {
                throw FileEditorError.fileTypeMismatch
            }
            if castedFile.state == .closed || castedFile.state == .created {
                let data = try DependencyManager.shared.fileSystemManager.readFile(name: name)
                castedFile.fieldsStore = try castedFile.from(data: data)
                castedFile.state = .opened
            } else {
                return castedFile
            }
        }
        let data = try DependencyManager.shared.fileSystemManager.readFile(name: name)
        let file = File(name: name)
        files[name] = file
        file.fieldsStore = try file.from(data: data)
        file.state = .opened
        
        var storedFields = [String: SIFieldValue]()
        file.fields().forEach {
            storedFields[$0] = SIFieldValue(key: $0, file: file)
        }
        file.storedFields = storedFields
        return file
    }
    
    func closeFile<File: SIFile>(_ file: File) async throws {
        guard file.state != .modified else { throw FileEditorError.fileNotSaved }
        file.fieldsStore = [:]
        file.state = .closed
        files[file.name] = nil
    }
    
    func readFile<File: SIFile>(_ file: File) async throws {
        guard file.state != .modified else { throw FileEditorError.fileNotSaved }
        let data = try DependencyManager.shared.fileSystemManager.readFile(name: file.name)
        file.fieldsStore = try file.from(data: data)
        file.state = .opened
    }
    
    func saveFile<File: SIFile>(_ file: File) async throws {
        guard file.state == .modified else { return }
        let data = try file.toData(fieldsStore: file.fieldsStore)
        try DependencyManager.shared.fileSystemManager.writeFile(name: file.name, data: data)
        file.state = .saved
    }
    
    func createFile<File: SIFile>(name: String) async throws -> File {
        let file = File(name: name)
        let data = try file.toData(fieldsStore: file.fieldsStore)
        try DependencyManager.shared.fileSystemManager.createFile(name: name, data: data)
        file.state = .created
        files[file.name] = file
        return file
    }
    
    func deleteFile<File: SIFile>(_ file: File) async throws {
        try await closeFile(file)
        try DependencyManager.shared.fileSystemManager.deleteFile(name: file.name)
        file.state = .deleted
    }
}
