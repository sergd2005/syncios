//
//  NoteViewModel.swift
//  SynciOS
//
//  Created by Sergii D on 2/2/25.
//
import Foundation

final class NoteViewModel: Identifiable, ObservableObject {
    private var initOn = true
    
    var id: String { note.name }
    
    let note: Note
    
    init(note: Note) {
        self.note = note
        self.name = note.name
        self.contents = note.contents
        initOn = false
    }
    
    @Published var name: String
    @Published var contents: String? {
        didSet {
            guard initOn == false else { return }
            note.contents = contents
        }
    }
}
