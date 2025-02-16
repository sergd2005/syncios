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
        self.contents = ""
        self.note.delegate = self
    }
    
    var name: String {
        get {
            note.name
        }
    }
    
    var contents: String {
        get {
            note.contents ?? ""
        }
        set {
            guard note.contents != newValue else { return }
            note.contents = newValue
        }
    }
    
    var contentsOnDisk: String {
        get {
            note.contentsOnDisk ?? ""
        }
        set {
            return
        }
    }
    
    var incomingContents: String {
        get {
            note.incomingContents ?? ""
        }
        set {
            return
        }
    }
    
    @Published var modified: Bool = false
    @Published var isInConflict: Bool = false
    @Published var isTwoWayConflict: Bool = false
}

extension String {
    func components(withLength length: Int) -> [String] {
        return stride(from: 0, to: count, by: length).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: length, limitedBy: endIndex) ?? endIndex
            return String(self[start..<end])
        }
    }
}

extension FileContentsViewModel: SIFileDelegate {
    func fileStateChanged<File: SIFile>(_ file: File) {
        Task { @MainActor in
//            switch file.state {
//            case .none:
//                ()
//            case .opened:
//                ()
//            case .read:
//                ()
////                name = note.name
////                contents = note.contents ?? ""
//            case .modified:
//                ()
//            case .saved:
//                ()
//            case .closed:
//                ()
//            case .deleted:
//                ()
//            case .unloaded:
//                ()
//            }
            isInConflict = (file.state == .conflict || file.state == .twoWayConflict)
            modified = file.state == .modified
            isTwoWayConflict = file.state == .twoWayConflict
        }
    }
}

extension FileContentsViewModel {
    func read() {
        Task {
            try await self.note.read()
        }
    }
    
    func unload() {
        Task {
            try await self.note.unload()
        }
    }
    
    func save() {
        Task {
            try await self.note.save()
            try await DependencyManager.shared.storageCoordinationProviding.commit(message: "Saving \(note.name) at \(Date())")
        }
    }
}
