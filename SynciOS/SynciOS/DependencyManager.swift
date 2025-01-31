//
//  DependencyManager.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//

protocol DependencyProviding {
    var fileSystemManager: FileSystemProviding { get }
    var pathsManager: PathsProviding { get }
}

final class DependencyProvider: DependencyProviding {
    let fileSystemManager: FileSystemProviding
    let pathsManager: PathsProviding
    
    init() {
        pathsManager = PathsManager()
        fileSystemManager = FileSystemManager(folderURL: pathsManager.localURL)
    }
}

final class DependencyManager {
    static let shared = DependencyManager()
    
    var dependencyProvider: DependencyProviding
    
    private init() {
        dependencyProvider = DependencyProvider()
    }
}

extension DependencyManager: DependencyProviding {
    var fileSystemManager: any FileSystemProviding {
        dependencyProvider.fileSystemManager
    }
    
    var pathsManager: any PathsProviding {
        dependencyProvider.pathsManager
    }
}
