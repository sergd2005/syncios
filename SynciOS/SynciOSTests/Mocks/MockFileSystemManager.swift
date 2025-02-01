//
//  MockFileSystemManager.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//

import Foundation
@testable import SynciOS

final class MockFileSystemManager: FileSystemProviding {
    func fileExists(name: String) -> Bool {
        false
    }
    
    func allFileNames() throws -> [String] {
        []
    }
    
    func parseJSONFile(name: String) throws -> [String : Any] {
        [:]
    }
    
    func readFile(name: String) throws -> Data {
        Data()
    }
    
    func writeFile(name: String, data: Data) throws {
        
    }
    
    func createFile(name: String, data: Data) throws {
        
    }
    
    func deleteFile(name: String) throws {
        
    }
}
