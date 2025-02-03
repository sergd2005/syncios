//
//  NoteViewModel.swift
//  SynciOS
//
//  Created by Sergii D on 2/2/25.
//
import Foundation

final class FileContentsViewModel: Identifiable, ObservableObject {
    var id: String { note.name }
    var note: Note
    
    init(note: Note) {
        self.note = note
        self.name = note.name
        self.contents = note.contents ?? ""
        self.note.delegate = self
        Task {
            try await self.note.read()
        }
    }
    
    @Published var name: String
    @Published var contents: String {
        didSet {
            if note.contents != contents {
                note.contents = contents
            }
        }
    }
    
    @Published var modified: Bool = false
}

extension FileContentsViewModel: SIFileDelegate {
    func fileStateChanged<File: SIFile>(_ file: File) {
        Task { @MainActor in
            switch file.state {
            case .none:
                ()
            case .opened:
                ()
            case .read:
                name = note.name
                contents = note.contents ?? ""
            case .modified:
                ()
            case .saved:
                ()
            case .closed:
                ()
            case .deleted:
                ()
            }
            modified = file.state == .modified
        }
    }
}
