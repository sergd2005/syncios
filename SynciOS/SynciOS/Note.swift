//
//  Note.swift
//  SynciOS
//
//  Created by Sergii D on 2/1/25.
//

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
}
