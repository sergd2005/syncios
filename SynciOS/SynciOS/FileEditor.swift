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
        case opened
        case modified
        case saved
        case closed
    }
    
    fileprivate var data: [String: Any]
    
    fileprivate let name: String
    
    fileprivate var storedFields: [String: SIFieldValue] = [:]
    
    fileprivate(set) var state: State = .none
    
    required init(name: String, data: [String : Any]) {
        self.data = data
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
            file?.data[key]
        }
        set {
            file?.state = .modified
            file?.data[key] = newValue
        }
    }
}

protocol FileEditingProvider {
    func openFile(name: String) throws -> SIFile
}

enum FileEditorError: Error {
    case fileTypeMismatch
    case fileNotSaved
}

final class FileEditor: FileEditingProvider {
    private var files = [String: SIFile]()
    
    func openFile<File: SIFile>(name: String) throws -> File {
        if let existingFile = files[name] {
            guard let castedFile = existingFile as? File else {
                throw FileEditorError.fileTypeMismatch
            }
            if castedFile.state == .closed {
                // TODO: call parsing data from File
                castedFile.data = ["contents": "test"]
                castedFile.state = .opened
            } else {
                return castedFile
            }
        }
        
        // TODO: call parsing data from File
        let file = File(name: name, data: ["contents": "test"])
        file.state = .opened
        
        var storedFields = [String: SIFieldValue]()
        file.fields().forEach {
            storedFields[$0] = SIFieldValue(key: $0, file: file)
        }
        file.storedFields = storedFields
        return file
    }
    
    func closeFile<File: SIFile>(_ file: File) throws {
        guard file.state != .modified else { throw FileEditorError.fileNotSaved }
        file.data = [:]
        file.state = .closed
    }
    
    func readFile<File: SIFile>(_ file: File) throws {
        guard file.state != .modified else { throw FileEditorError.fileNotSaved }
        // TODO: call parsing data from File
        file.data = ["contents": "test"]
        file.state = .opened
    }
    
    func saveFile<File: SIFile>(_ file: File) throws {
        guard file.state == .modified else { return }
        // TODO: write file to disk
        file.state = .saved
    }
}


//@propertyWrapper struct SIField<Value: SIFieldValue> {
//    var wrappedValue: Value
//}
