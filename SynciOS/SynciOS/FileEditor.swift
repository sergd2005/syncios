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
        case read
        case modified
        case saved
        case closed
        case deleted
    }
    
    fileprivate weak var editor: FileEditingProvider?
    
    fileprivate var dataStore: [String: Any] = [:]
    
    let name: String
    
    fileprivate lazy var fieldsMap: [String: SIFieldValue] = {
        var fieldsMap = [String: SIFieldValue]()
        fields().forEach {
            fieldsMap[$0] = SIFieldValue(key: $0, file: self)
        }
        return fieldsMap
    }()
    
    fileprivate(set) var state: State = .none
    
    required init(name: String, editor: FileEditingProvider) {
        self.name = name
        self.editor = editor
    }
    
    func fields() -> [String] {
        fatalError("function should be overriden")
    }
    
    func field<T>(for key: String) -> T? {
        fieldsMap[key]?.value as? T
    }
    
    func setField<T>(value: T?, for key: String) {
        fieldsMap[key]?.value = value
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
    
    fileprivate var value: Any?  {
        get {
            if let file, file.state == .opened {
                do {
                    _ = try file.editor?.readFile(file)
                } catch(let error) {
                    print(error.localizedDescription)
                }
            }
            return file?.dataStore[key]
        }
        set {
            file?.state = .modified
            file?.dataStore[key] = newValue
        }
    }
}

protocol FileEditingProvider: AnyObject {
    func openFile<File: SIFile>(file: File) async throws -> File
    func openFile<File: SIFile>(name: String) async throws -> File
    func closeFile<File: SIFile>(_ file: File) async throws
    func readFile<File: SIFile>(_ file: File) throws
    func saveFile<File: SIFile>(_ file: File) async throws
    func createFile<File: SIFile>(name: String) async throws -> File
    func deleteFile<File: SIFile>(_ file: File) async throws
    
    func allFileNames() throws -> [String]
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
            castedFile.state = .opened
            castedFile.dataStore = [:]
            return castedFile
        }
        
        let file = File(name: name, editor: self)
        files[name] = file
        file.state = .opened
        return file
    }
    
    func closeFile<File: SIFile>(_ file: File) async throws {
        guard file.state != .modified else { throw FileEditorError.fileNotSaved }
        file.dataStore = [:]
        file.state = .closed
        files[file.name] = nil
    }
    
    nonisolated func readFile<File: SIFile>(_ file: File) throws {
        guard file.state != .modified else { throw FileEditorError.fileNotSaved }
        let data = try DependencyManager.shared.fileSystemManager.readFile(name: file.name)
        file.dataStore = try file.from(data: data)
        file.state = .read
    }
    
    func saveFile<File: SIFile>(_ file: File) async throws {
        guard file.state == .modified else { return }
        let data = try file.toData(fieldsStore: file.dataStore)
        try DependencyManager.shared.fileSystemManager.writeFile(name: file.name, data: data)
        file.state = .saved
    }
    
    func createFile<File: SIFile>(name: String) async throws -> File {
        let file = File(name: name, editor: self)
        let data = try file.toData(fieldsStore: file.dataStore)
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
    
    nonisolated func allFileNames() throws -> [String] {
        try DependencyManager.shared.fileSystemManager.allFileNames()
    }
}
