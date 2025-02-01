//
//  EditorTests.swift
//  SynciOS
//
//  Created by Sergii D on 2/1/25.
//

import Testing
@testable import SynciOS

struct EditorTests {
    @Test func openNotes() async throws {
        let editor = FileEditor()
        let note: Note = try editor.openFile(name: "test.json")
        #expect(note.contents == "test")
        #expect(note.state == .opened)
        note.contents = "new content"
        #expect(note.contents == "new content")
        #expect(note.state == .modified)
    }
    
    @Test func openTwice() async throws {
        let editor = FileEditor()
        let note: Note = try editor.openFile(name: "test.json")
        let noteOpenedAgain: Note = try editor.openFile(name: "test.json")
        #expect(note == noteOpenedAgain)
        #expect(note.state == .opened)
    }
    
    @Test func close() async throws {
        let editor = FileEditor()
        let note: Note = try editor.openFile(name: "test.json")
        try editor.closeFile(note)
        #expect(note.state == .closed)
        #expect(note.contents == nil)
    }
    
    @Test func closeModified() async throws {
        let editor = FileEditor()
        let note: Note = try editor.openFile(name: "test.json")
        note.contents = "Some content"
        do {
            try editor.closeFile(note)
        } catch(let error) {
            switch error {
            case is FileEditorError:
                #expect(error as! FileEditorError == .fileNotSaved)
            default:
                assertionFailure(error.localizedDescription)
            }
        }
        #expect(note.state == .modified)
        #expect(note.contents == "Some content")
    }
    
    @Test func saveModifiedAndClose() async throws {
        let editor = FileEditor()
        let note: Note = try editor.openFile(name: "test.json")
        note.contents = "Some content"
        #expect(note.state == .modified)
        try editor.saveFile(note)
        #expect(note.state == .saved)
        try editor.closeFile(note)
        #expect(note.state == .closed)
    }
    
    @Test func readFile() async throws {
        let editor = FileEditor()
        let note: Note = try editor.openFile(name: "test.json")
        try editor.readFile(note)
        #expect(note.state == .opened)
    }
    
    @Test func readModified() async throws {
        let editor = FileEditor()
        let note: Note = try editor.openFile(name: "test.json")
        note.contents = "Some content"
        do {
            try editor.readFile(note)
        } catch(let error) {
            switch error {
            case is FileEditorError:
                #expect(error as! FileEditorError == .fileNotSaved)
            default:
                assertionFailure(error.localizedDescription)
            }
        }
        #expect(note.state == .modified)
        #expect(note.contents == "Some content")
    }
}
