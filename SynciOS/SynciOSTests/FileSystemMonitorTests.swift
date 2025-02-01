//
//  Untitled.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//
import Testing
@testable import SynciOS
import Foundation

struct FileSystemMonitorTests {
    @Test func monitor() async throws {
        print(DependencyManager.shared.pathsManager.localURL)
        let fileName = "test_file.json"
        let fileSystemManager = DependencyManager.shared.fileSystemManager
        
        if !fileSystemManager.fileExists(name: fileName) {
            try fileSystemManager.createFile(name: "test_file.json", data: Data())
        }
        
        let fileSystemMonitor = try FileSystemMonitor(name: "test_file.json")
        try fileSystemManager.deleteFile(name: "test_file.json")
        sleep(500)
    }
}
