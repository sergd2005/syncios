//
//  MockFileSystemManager.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//

@testable import SynciOS

final class MockFileSystemManager: FileSystemProviding {
    func allFileNames() throws -> [String] {
        []
    }
    
    func parseJSONFile(name: String) throws -> [String : Any] {
        [:]
    }
    
    func writeFile(name: String, data: [String : Any]) throws {
        
    }
}
