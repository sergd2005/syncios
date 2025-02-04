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
        case conflict
        case twoWayConflict
        case unloaded
        case closed
        case deleted
    }
    
    fileprivate weak var editor: FileEditingProvider?
    
    fileprivate(set) var state: State = .none {
        didSet {
            delegate?.fileStateChanged(self)
        }
    }
    
    fileprivate var modifiedDate: Date?
    
    let name: String
    
    weak var delegate: SIFileDelegate?
    fileprivate let fileStorage: SIFileStorage
    fileprivate(set) var currentFileStorage: SIFileStorage?
    fileprivate(set) var incomingFileStorage: SIFileStorage?
    
    required init(name: String, fileStorage: SIFileStorage, editor: FileEditingProvider) {
        self.name = name
        self.editor = editor
        self.fileStorage = fileStorage
    }
    
    func fields() -> [String] {
        fatalError("function should be overriden")
    }
    
    func field<T>(for key: String) -> T? {
        fileStorage.field(for: key)
    }
    
    func setField<T>(value: T?, for key: String) {
        fileStorage.setField(value: value, for: key)
    }
    
    func currentFileField<T>(for key: String) -> T? {
        currentFileStorage?.field(for: key)
    }
    
    func setCurrentFileField<T>(value: T?, for key: String) {
        currentFileStorage?.setField(value: value, for: key)
    }
    
    func incomingField<T>(for key: String) -> T? {
        incomingFileStorage?.field(for: key)
    }
    
    func setIncomingField<T>(value: T?, for key: String) {
        incomingFileStorage?.setField(value: value, for: key)
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
    
    func unload() async throws {
        try await editor?.unloadFile(self)
    }
    
    func resolveWithIncoming() {
        guard let incomingFileStorage else { return }
        fileStorage.dataStore = incomingFileStorage.dataStore
        self.incomingFileStorage = nil
        currentFileStorage = nil
        state = .modified
    }
    
    func resolveWithCurrent() {
        incomingFileStorage = nil
        currentFileStorage = nil
        state = .modified
    }
    
    func resolveWithCurrentOnDisk() {
        guard let currentFileStorage else { return }
        fileStorage.dataStore = currentFileStorage.dataStore
        incomingFileStorage = nil
        self.currentFileStorage = nil
        state = .modified
    }
}

extension SIFile: Equatable {
    static func == (lhs: SIFile, rhs: SIFile) -> Bool {
        lhs.name == rhs.name
    }
}

class SIFileStorage {
    fileprivate weak var file: SIFile?
    fileprivate var dataStore: SIFileDataStore = [:]
    
    fileprivate lazy var fieldsMap: [String: SIFieldValue] = {
        var fieldsMap = [String: SIFieldValue]()
        file?.fields().forEach {
            fieldsMap[$0] = SIFieldValue(key: $0, fileStorage: self)
        }
        return fieldsMap
    }()
    
    init(file: SIFile? = nil, dataStore: SIFileDataStore = [:]) {
        self.file = file
        self.dataStore = dataStore
    }
    
    func field<T>(for key: String) -> T? {
        fieldsMap[key]?.value as? T
    }
    
    func setField<T>(value: T?, for key: String) {
        fieldsMap[key]?.value = value
    }
    
}

class SIFieldValue {
    fileprivate let key: String
    fileprivate weak var fileStorage: SIFileStorage?

    fileprivate init(key: String, fileStorage: SIFileStorage) {
        self.key = key
        self.fileStorage = fileStorage
    }
    
    fileprivate var value: Any?  {
        get {
            return fileStorage?.dataStore[key]
        }
        set {
            guard let file = fileStorage?.file else { return }
            switch file.state {
            case .none, .opened, .closed, .deleted, .unloaded, .conflict, .twoWayConflict:
                ()
            case .read, .saved, .modified:
                file.state = .modified
                fileStorage?.dataStore[key] = newValue
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
    func unloadFile<File: SIFile>(_ file: File) async throws
    func allFileNames() throws -> [String]
}

enum FileEditorError: Error {
    case fileStateIsUndefined
    case fileTypeMismatch
    case fileNotSaved
    case fileIsNotUnloaded
    case fileIsClosed
    case fileIsDeleted
    case unableToGetModifiedDate
    case fileIsInConflict
    case failedToParseString
}

actor FileEditor: FileEditingProvider {
    private var files = [String: SIFile]()
    
    func openFile<File: SIFile>(file: File) async throws {
        switch file.state {
        case .none, .read, .saved, .closed, .unloaded:
            files[file.name] = file
            file.state = .opened
        case .opened:
            // already opened noop
            ()
        case .conflict, .twoWayConflict:
            throw FileEditorError.fileIsInConflict
        case .modified:
            throw FileEditorError.fileNotSaved
        case .deleted:
            throw FileEditorError.fileIsDeleted
        }
    }
    
    func openFile<File: SIFile>(name: String) async throws -> File {
        guard let file = files[name, default: File(name: name, fileStorage: SIFileStorage(), editor: self)] as? File else {
            throw FileEditorError.fileTypeMismatch
        }
        file.fileStorage.file = file
        try await openFile(file: file)
        return file
    }
    
    func unloadFile<File: SIFile>(_ file: File) async throws {
        switch file.state {
        case .none, .opened, .read, .saved, .closed:
            file.fileStorage.dataStore = [:]
            file.modifiedDate = nil
            file.state = .unloaded
        case .modified:
            throw FileEditorError.fileNotSaved
        case .unloaded:
            // NOOP
            ()
        case .conflict, .twoWayConflict:
            throw FileEditorError.fileIsInConflict
        case .deleted:
            throw FileEditorError.fileIsDeleted
        }
    }
    
    func closeFile<File: SIFile>(_ file: File) async throws {
        try await unloadFile(file)
        guard file.state == .unloaded else { throw FileEditorError.fileIsNotUnloaded }
        files[file.name] = nil
        file.state = .closed
    }
    
    func parseConflict(_ data: Data) async throws -> (SIFileDataStore, SIFileDataStore) {
        guard let string = String(data: data, encoding: .utf8) else {
            throw FileEditorError.failedToParseString
        }
        let split = string.components(separatedBy: "<<<<<<< HEAD")
        guard let currentContent = split[1].components(separatedBy: "=======").first,
              let incomingContentSplit = split[1].components(separatedBy: "=======").last,
              let incomingContent = incomingContentSplit.components(separatedBy: ">>>>>>>").first
        else {
            throw FileEditorError.failedToParseString
        }
        let current = "{" + currentContent + "}"
        let incoming = "{" + incomingContent + "}"
        guard let currentData = current.data(using: .utf8),
              let incomingData = incoming.data(using: .utf8),
              let jsonDictCurrent = try JSONSerialization.jsonObject(with: currentData, options: .fragmentsAllowed) as? SIFileDataStore,
              let jsonDictIncoming = try JSONSerialization.jsonObject(with: incomingData, options: .fragmentsAllowed) as? SIFileDataStore
        else {
            throw FileEditorError.failedToParseString
        }
        
        return (jsonDictCurrent, jsonDictIncoming)
    }
    
    func readFile<File: SIFile>(_ file: File) async throws {
        switch file.state {
        case .none:
            throw FileEditorError.fileStateIsUndefined
        case .opened, .read, .saved, .modified, .unloaded:
            guard let modifiedDateOnDisk = try DependencyManager.shared.fileSystemManager.getModifiedDate(name: file.name) else {
                throw FileEditorError.unableToGetModifiedDate
            }
            if let modifiedDate = file.modifiedDate, modifiedDate == modifiedDateOnDisk  {
                return
            } else {
                let data = try DependencyManager.shared.fileSystemManager.readFile(name: file.name)
                if let parsedDataStore = try? file.from(data: data) {
                    if file.state == .modified {
                        file.incomingFileStorage = SIFileStorage(file: file, dataStore: parsedDataStore)
                        file.state = .conflict
                    } else {
                        file.fileStorage.dataStore = parsedDataStore
                        file.modifiedDate = modifiedDateOnDisk
                        file.state = .read
                    }
                } else {
                    let result = try await parseConflict(data)
                    if file.state == .modified {
                        file.currentFileStorage = SIFileStorage(file: file, dataStore: result.0)
                        file.incomingFileStorage = SIFileStorage(file: file, dataStore: result.1)
                        file.state = .twoWayConflict
                    } else {
                        file.fileStorage.dataStore = result.0
                        file.incomingFileStorage = SIFileStorage(file: file, dataStore: result.1)
                        file.modifiedDate = modifiedDateOnDisk
                        file.state = .conflict
                    }
                }
            }
        case .conflict, .twoWayConflict:
            throw FileEditorError.fileIsInConflict
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
        case .opened, .read, .saved, .unloaded:
            // NOOP
            ()
        case .modified:
            // TODO: check modified date
            let data = try file.toData(dataStore: file.fileStorage.dataStore)
            try DependencyManager.shared.fileSystemManager.writeFile(name: file.name, data: data)
            guard let modifiedDateOnDisk = try DependencyManager.shared.fileSystemManager.getModifiedDate(name: file.name) else {
                throw FileEditorError.unableToGetModifiedDate
            }
            file.modifiedDate = modifiedDateOnDisk
            file.state = .saved
        case .closed:
            throw FileEditorError.fileIsClosed
        case .conflict, .twoWayConflict:
            throw FileEditorError.fileIsInConflict
        case .deleted:
            throw FileEditorError.fileIsDeleted
        }
    }
    
    func createFile<File: SIFile>(name: String) async throws -> File {
        let file: File = try await openFile(name: name)
        let data = try file.toData(dataStore: file.fileStorage.dataStore)
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
