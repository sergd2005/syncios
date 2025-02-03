//
//  Editor.swift
//  SynciOS
//
//  Created by Sergii D on 2/1/25.
//

import Foundation

typealias SIFileDataStore = [String: Any]

protocol SIFileDelegate: AnyObject {
    func fileChangedOnDisk<File: SIFile>(_ file: File)
    func fileStateChanged<File: SIFile>(_ file: File)
}

extension SIFileDelegate {
    func fileChangedOnDisk<File: SIFile>(_ file: File) {}
    func fileStateChanged<File: SIFile>(_ file: File) {}
}

class SIFile {
    enum State {
        case none
        case opened
        case read
        case modified
        case saved
        case closed
        case deleted
    }
    
    fileprivate weak var editor: FileEditingProvider?
    
    fileprivate(set) var state: State = .none {
        didSet {
            delegate?.fileStateChanged(self)
        }
    }
    
    fileprivate var dataStore: SIFileDataStore = [:]
    fileprivate var modifiedDate: Date?
    
    let name: String
    
    weak var delegate: SIFileDelegate?
    
    fileprivate lazy var fieldsMap: [String: SIFieldValue] = {
        var fieldsMap = [String: SIFieldValue]()
        fields().forEach {
            fieldsMap[$0] = SIFieldValue(key: $0, file: self)
        }
        return fieldsMap
    }()
    
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
    
    func toData(dataStore: SIFileDataStore) throws -> Data {
        fatalError("should be overriden")
    }
    
    func from(data: Data) throws -> SIFileDataStore {
        fatalError("should be overriden")
    }
    
    func open() async throws {
        try await editor?.openFile(file: self)
    }
    
    func read() async throws {
        try await editor?.readFile(self)
    }
    
    func save() async throws {
        try await editor?.saveFile(self)
    }
    
    func delete() async throws {
        try await editor?.deleteFile(self)
    }
    
    func close() async throws {
        try await editor?.closeFile(self)
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
            guard let file else { return nil }
            return file.dataStore[key]
        }
        set {
            guard let file else { return }
            switch file.state {
            case .none, .opened, .closed, .deleted:
                ()
            case .read, .saved, .modified:
                file.state = .modified
                file.dataStore[key] = newValue
            }
        }
    }
}

protocol FileEditingProvider: AnyObject {
    func openFile<File: SIFile>(file: File) async throws
    func openFile<File: SIFile>(name: String) async throws -> File
    func closeFile<File: SIFile>(_ file: File) async throws
    func readFile<File: SIFile>(_ file: File) async throws
    func saveFile<File: SIFile>(_ file: File) async throws
    func createFile<File: SIFile>(name: String) async throws -> File
    func deleteFile<File: SIFile>(_ file: File) async throws
    func allFileNames() throws -> [String]
}

enum FileEditorError: Error {
    case fileStateIsUndefined
    case fileTypeMismatch
    case fileNotSaved
    case fileIsClosed
    case fileIsDeleted
    case unableToGetModifiedDate
}

actor FileEditor: FileEditingProvider {
    private var files = [String: SIFile]()
    
    func openFile<File: SIFile>(file: File) async throws {
        switch file.state {
        case .none, .read, .saved, .closed:
            file.state = .opened
            file.dataStore = [:]
            files[file.name] = file
        case .opened:
            // already opened noop
            ()
        case .modified:
            throw FileEditorError.fileNotSaved
        case .deleted:
            throw FileEditorError.fileIsDeleted
        }
    }
    
    func openFile<File: SIFile>(name: String) async throws -> File {
        guard let file = files[name, default: File(name: name, editor: self)] as? File else {
            throw FileEditorError.fileTypeMismatch
        }
        try await openFile(file: file)
        return file
    }
    
    func closeFile<File: SIFile>(_ file: File) async throws {
        switch file.state {
        case .none, .opened, .read, .saved:
            file.dataStore = [:]
            file.state = .closed
            file.modifiedDate = nil
        case .modified:
            throw FileEditorError.fileNotSaved
        case .closed:
            // NOOP
            ()
        case .deleted:
            throw FileEditorError.fileIsDeleted
        }
    }
    
    nonisolated func readFile<File: SIFile>(_ file: File) async throws {
        switch file.state {
        case .none:
            throw FileEditorError.fileStateIsUndefined
        case .opened, .read, .saved, .modified:
            guard let modifiedDateOnDisk = try DependencyManager.shared.fileSystemManager.getModifiedDate(name: file.name) else {
                throw FileEditorError.unableToGetModifiedDate
            }
            if let modifiedDate = file.modifiedDate, modifiedDate == modifiedDateOnDisk  {
                return
            } else {
                // file was never read
                let data = try DependencyManager.shared.fileSystemManager.readFile(name: file.name)
                file.dataStore = try file.from(data: data)
                file.state = .read
                file.modifiedDate = modifiedDateOnDisk
                if file.state == .modified {
                  // TODO: notify about conflict
                } else {
                    file.delegate?.fileChangedOnDisk(file)
                }
            }
        case .closed:
            throw FileEditorError.fileIsClosed
        case .deleted:
            throw FileEditorError.fileIsDeleted
        }
    }
    
    func saveFile<File: SIFile>(_ file: File) async throws {
        switch file.state {
        case .none:
            throw FileEditorError.fileStateIsUndefined
        case .opened, .read, .saved:
            // NOOP
            ()
        case .modified:
            // TODO: check modified date
            let data = try file.toData(dataStore: file.dataStore)
            try DependencyManager.shared.fileSystemManager.writeFile(name: file.name, data: data)
            file.state = .saved
        case .closed:
            throw FileEditorError.fileIsClosed
        case .deleted:
            throw FileEditorError.fileIsDeleted
        }
    }
    
    func createFile<File: SIFile>(name: String) async throws -> File {
        let file: File = try await openFile(name: name)
        let data = try file.toData(dataStore: file.dataStore)
        try DependencyManager.shared.fileSystemManager.createFile(name: name, data: data)
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
