//
//  EditorTests.swift
//  SynciOS
//
//  Created by Sergii D on 2/1/25.
//

import Foundation
import Testing
@testable import SynciOS

final class FileEditorTests {
    let editor = DependencyManager.shared.fileEditor
    
    @Test func openNotes() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        #expect(note.contents == "")
        #expect(note.state == .read)
        note.contents = "new content"
        #expect(note.contents == "new content")
        #expect(note.state == .modified)
        try await editor.saveFile(note)
        try await editor.deleteFile(note)
    }
    
    @Test func openTwice() async throws {
        let name = UUID().uuidString + ".json"
        let newNote: Note = try await editor.createFile(name: name)
        let noteOpenedAgain: Note = try await editor.openFile(name: name)
        #expect(newNote == noteOpenedAgain)
        #expect(newNote.state == .opened)
        try await newNote.delete()
    }
    
    @Test func close() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.close()
        #expect(note.state == .closed)
        #expect(note.contents == nil)
        try await note.delete()
    }
    
    @Test func closeModified() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "Some content"
        var returnedError: Error?
        do {
            try await editor.closeFile(note)
        } catch(let error) {
            returnedError = error
            switch error {
            case is FileEditorError:
                #expect(error as! FileEditorError == .fileNotSaved)
            default:
                assertionFailure(error.localizedDescription)
            }
        }
        #expect(returnedError != nil)
        #expect(note.state == .modified)
        #expect(note.contents == "Some content")
        try await note.save()
        try await note.delete()
    }
    
    @Test func saveModifiedAndClose() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "Some content"
        #expect(note.state == .modified)
        try await note.save()
        #expect(note.state == .saved)
        try await note.close()
        #expect(note.state == .closed)
        try await note.delete()
    }
    
    @Test func readFile() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        #expect(note.state == .opened)
        try await editor.deleteFile(note)
    }
    
    @Test func readModifiedInMemory() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "Some content"
        var returnedError: Error?
        do {
            try await editor.readFile(note)
        } catch(let error) {
            returnedError = error
        }
        #expect(returnedError == nil)
        #expect(note.state == .modified)
        #expect(note.contents == "Some content")
        try await note.save()
        try await note.delete()
    }
    
    @Test func modifyFileSaveCloseAndOpen() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        #expect(note.state == .opened)
        try await note.read()
        #expect(note.contents == "")
        note.contents = "Modified contents"
        #expect(note.state == .modified)
        try await note.save()
        #expect(note.state == .saved)
        try await note.close()
        #expect(note.state == .closed)
        #expect(note.contents == nil)
        try await editor.openFile(file: note)
        #expect(note.state == .opened)
        try await note.read()
        #expect(note.contents == "Modified contents")
        try await note.delete()
        #expect(note.state == .deleted)
    }
    
    @Test func deleteFile() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await editor.deleteFile(note)
        #expect(note.state == .deleted)
    }
    
    @Test func openModifiedFile() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "New Content"
        
        var returnedError: Error?
        do {
            try await editor.openFile(file: note)
        } catch(let error) {
            returnedError = error
            switch error {
            case is FileEditorError:
                #expect(error as! FileEditorError == .fileNotSaved)
            default:
                assertionFailure(error.localizedDescription)
            }
        }
        
        #expect(returnedError != nil)
        #expect(note.state == .modified)
        try await editor.saveFile(note)
        #expect(note.state == .saved)
        try await editor.deleteFile(note)
        #expect(note.state == .deleted)
    }
    
    @Test func readModifiedFile() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "New Content"
        try await editor.saveFile(note)
        
        note.contents = "New Content2"
        try await note.read()
        #expect(note.state == .modified)
        #expect(note.contents == "New Content2")
        try await editor.saveFile(note)
        #expect(note.state == .saved)
        try await editor.deleteFile(note)
        #expect(note.state == .deleted)
    }
    
    @Test func resolveWithIncoming() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "New Content"
        #expect(note.state == .modified)
        #expect(note.contents == "New Content")
        let data = try JSONSerialization.data(withJSONObject: [NoteFields.contents.rawValue : "testdata"], options: .prettyPrinted)
        try DependencyManager.shared.fileSystemManager.writeFile(name: name, data: data)
        try await note.read()
        // TODO: should conflict state
        #expect(note.state == .conflict)
        #expect(note.contents == "New Content")
        #expect(note.incomingContents == "testdata")
        note.resolveWithIncoming()
        #expect(note.state == .modified)
        #expect(note.contents == "testdata")
        try await editor.saveFile(note)
        #expect(note.state == .saved)
        try await editor.deleteFile(note)
        #expect(note.state == .deleted)
    }
    
    @Test func resolveWithCurrent() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "New Content"
        #expect(note.state == .modified)
        #expect(note.contents == "New Content")
        let data = try JSONSerialization.data(withJSONObject: [NoteFields.contents.rawValue : "testdata"], options: .prettyPrinted)
        try DependencyManager.shared.fileSystemManager.writeFile(name: name, data: data)
        try await note.read()
        // TODO: should conflict state
        #expect(note.state == .conflict)
        #expect(note.contents == "New Content")
        #expect(note.incomingContents == "testdata")
        note.resolveWithCurrent()
        #expect(note.state == .modified)
        #expect(note.contents == "New Content")
        try await editor.saveFile(note)
        #expect(note.state == .saved)
        try await editor.deleteFile(note)
        #expect(note.state == .deleted)
    }
    
    @Test func modifyFileSaveAndReadWhileModified() async throws {
        let name = UUID().uuidString + ".json"
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "New Content"
        try await editor.saveFile(note)
        #expect(note.state == .saved)
        #expect(note.contents == "New Content")
        let data = try JSONSerialization.data(withJSONObject: [NoteFields.contents.rawValue : "testdata"], options: .prettyPrinted)
        try DependencyManager.shared.fileSystemManager.writeFile(name: name, data: data)
        try await note.read()
        #expect(note.state == .read)
        #expect(note.contents == "testdata")
        try await editor.deleteFile(note)
        #expect(note.state == .deleted)
    }
    
    @Test func mergeConflictOnDisk() async throws {
        let name = UUID().uuidString + ".json"
        
        guard let data = "{\n<<<<<<< HEAD\n  \"contents\" : \"1\"\n=======\n  \"contents\" : \"tests\"\n>>>>>>> dc7af96d37cd1fefcd134d63e043c4ea0f9e0c81\n}".data(using: .utf8) else {
            assertionFailure("failed to parse data")
            return
        }
        
        try DependencyManager.shared.fileSystemManager.writeFile(name: name, data: data)
        let note: Note = try await editor.openFile(name: name)
        try await note.read()
        #expect(note.state == .conflict)
        #expect(note.contents == "1")
        #expect(note.incomingContents == "tests")
        note.resolveWithCurrent()
        try await note.save()
        #expect(note.state == .saved)
        try await note.unload()
        #expect(note.state == .unloaded)
        try await note.read()
        #expect(note.state == .read)
        #expect(note.contents == "1")
        try await note.delete()
    }
    
    @Test func twoWayMergeConflictOnDisk() async throws {
        let name = UUID().uuidString + ".json"
        guard let data = "{\n<<<<<<< HEAD\n  \"contents\" : \"1\"\n=======\n  \"contents\" : \"tests\"\n>>>>>>> dc7af96d37cd1fefcd134d63e043c4ea0f9e0c81\n}".data(using: .utf8) else {
            assertionFailure("failed to parse data")
            return
        }
        let note: Note = try await editor.createFile(name: name)
        try await note.read()
        note.contents = "New Content"
        try DependencyManager.shared.fileSystemManager.writeFile(name: name, data: data)
        try await note.read()
        #expect(note.state == .twoWayConflict)
        #expect(note.contents == "New Content")
        #expect(note.incomingContents == "tests")
        #expect(note.contentsOnDisk == "1")
        note.resolveWithCurrent()
        try await note.save()
        #expect(note.state == .saved)
        try await note.unload()
        #expect(note.state == .unloaded)
        try await note.read()
        #expect(note.state == .read)
        #expect(note.contents == "New Content")
        try await note.delete()
    }
}
