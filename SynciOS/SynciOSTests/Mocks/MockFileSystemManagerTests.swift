//
//  MockFileSystemManagerTests.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//
import Testing

struct MockFileSystemManagerTests {
    
    @Test func createFile() async throws {
        let fileSystemManager = MockFileSystemManager()
        try fileSystemManager.createFile(name: "New File", data: ["test" : "test"])
    }
}
