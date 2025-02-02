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
    
    override func toData(fieldsStore: [String: Any]) throws -> Data {
        let dict = (fieldsStore.isEmpty == true ? ["contents" : ""] : fieldsStore)
        return try JSONSerialization.data(withJSONObject: dict)
    }
    
    override func from(data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        guard let castedObject = object as? [String: Any] else { throw NoteError.failedToCastDataObject }
        return castedObject
    }
}
