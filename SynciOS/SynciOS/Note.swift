//
//  Note.swift
//  SynciOS
//
//  Created by Sergii D on 2/1/25.
//

import Foundation

enum NoteError: Error {
    case failedToCastDataObject
}

enum NoteFields: String, CaseIterable {
    case contents
    case comment
}

final class Note: SIFile {
    
    override func fields() -> [String] {
        NoteFields.allCases.map { $0.rawValue }
    }
    
    var contents: String? {
        get {
            field(for: NoteFields.contents.rawValue)
        }
        set {
            setField(value: newValue, for: NoteFields.contents.rawValue)
        }
    }
    
    override func toData(dataStore: SIFileDataStore) throws -> Data {
        // TODO: move to SIFile generic implementation
        let dict = (dataStore.isEmpty == true ? [NoteFields.contents.rawValue : "", NoteFields.comment.rawValue : ""] : dataStore)
        return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
    }
    
    override func from(data: Data) throws -> SIFileDataStore {
        let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        guard let castedObject = object as? [String: Any] else { throw NoteError.failedToCastDataObject }
        return castedObject
    }
}

