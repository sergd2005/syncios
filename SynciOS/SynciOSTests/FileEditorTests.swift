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
    
    @Test func modifyFileAndReadWhileModified() async throws {
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
}
