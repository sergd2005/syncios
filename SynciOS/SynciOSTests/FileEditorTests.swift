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
        _ = try await editor.openFile(file: note)
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
        let note: Note = try await editor.openFile(name: name)
        let noteOpenedAgain: Note = try await editor.openFile(name: name)
        #expect(note == noteOpenedAgain)
        #expect(note.state == .opened)
        try await editor.deleteFile(note)
    }
    
    @Test func close() async throws {
        let name = UUID().uuidString + ".json"
        let newNote: Note = try await editor.createFile(name: name)
        let note: Note = try await editor.openFile(name: name)
        try await editor.closeFile(note)
        #expect(note.state == .closed)
        #expect(note.contents == nil)
        try await editor.deleteFile(note)
    }
    
    @Test func closeModified() async throws {
        let name = UUID().uuidString + ".json"
        let newNote: Note = try await editor.createFile(name: name)
        let note: Note = try await editor.openFile(name: name)
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
        try await editor.saveFile(note)
        try await editor.deleteFile(note)
    }
    
    @Test func saveModifiedAndClose() async throws {
        let name = UUID().uuidString + ".json"
        let newNote: Note = try await editor.createFile(name: name)
        let note: Note = try await editor.openFile(name: name)
        note.contents = "Some content"
        #expect(note.state == .modified)
        try await editor.saveFile(note)
        #expect(note.state == .saved)
        try await editor.closeFile(note)
        #expect(note.state == .closed)
        try await editor.deleteFile(note)
    }
    
    @Test func readFile() async throws {
        let name = UUID().uuidString + ".json"
        let newNote: Note = try await editor.createFile(name: name)
        let note: Note = try await editor.openFile(name: name)
        #expect(note.state == .opened)
        try await editor.deleteFile(note)
    }
    
    @Test func readModified() async throws {
        let name = UUID().uuidString + ".json"
        let newNote: Note = try await editor.createFile(name: name)
        let note: Note = try await editor.openFile(name: name)
        note.contents = "Some content"
        var returnedError: Error?
        do {
            try editor.readFile(note)
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
        try await editor.saveFile(note)
        try await editor.deleteFile(note)
    }
    
    @Test func modifyFileSaveCloseAndOpen() async throws {
        let name = UUID().uuidString + ".json"
        var note: Note = try await editor.createFile(name: name)
        note = try await editor.openFile(file: note)
        #expect(note.state == .opened)
        #expect(note.contents == "")
        note.contents = "Modified contents"
        #expect(note.state == .modified)
        try await editor.saveFile(note)
        #expect(note.state == .saved)
        try await editor.closeFile(note)
        #expect(note.state == .closed)
        #expect(note.contents == nil)
        note = try await editor.openFile(file: note)
        #expect(note.state == .opened)
        #expect(note.contents == "Modified contents")
        try await editor.deleteFile(note)
        #expect(note.state == .deleted)
    }
    
    @Test func deleteFile() async throws {
        let name = UUID().uuidString + ".json"
        var note: Note = try await editor.createFile(name: name)
        try await editor.deleteFile(note)
        #expect(note.state == .deleted)
    }
    
    @Test func openModifiedFile() async throws {
        let name = UUID().uuidString + ".json"
        var note: Note = try await editor.createFile(name: name)
        note.contents = "New Content"
        
        var returnedError: Error?
        do {
            note = try await editor.openFile(file: note)
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
}
