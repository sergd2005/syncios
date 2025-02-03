//
//  FileListViewModel.swift
//  SynciOS
//
//  Created by Sergii D on 2/2/25.
//
import Foundation

final class FileListViewModel: Identifiable, ObservableObject {
    var id: String { note.name }
    let note: Note
    
    init(note: Note) {
        self.note = note
    }
    
    var name: String {
        self.note.name
    }
}
