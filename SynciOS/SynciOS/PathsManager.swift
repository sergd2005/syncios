//
//  PathsManager.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//
import Foundation

protocol PathsProviding {
    var localURL: URL { get }
}

final class PathsManager: PathsProviding {
    
    let localURL: URL
    
    init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localURL = documentsDirectory.appendingPathComponent("repo")
    }
}

final class MockPathsManager: PathsProviding {
    let localURL: URL
    
    init(localURL: URL) {
        self.localURL = localURL
    }
}
