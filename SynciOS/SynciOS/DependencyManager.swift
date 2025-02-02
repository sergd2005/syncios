//
//  DependencyManager.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//

protocol DependencyProviding {
    var fileSystemManager: FileSystemProviding { get }
    var pathsManager: PathsProviding { get }
    var fileEditor: FileEditingProvider { get }
}

final class DependencyProvider: DependencyProviding {
    let fileSystemManager: FileSystemProviding
    let pathsManager: PathsProviding
    let fileEditor: FileEditingProvider
    
    init() throws {
        pathsManager = PathsManager()
        fileSystemManager = try FileSystemManager(folderURL: pathsManager.localURL)
        fileEditor = FileEditor()
    }
}

final class MockDependencyProvider: DependencyProviding {
    let fileSystemManager: FileSystemProviding
    let pathsManager: PathsProviding
    let fileEditor: FileEditingProvider
    
    init(fileSystemManager: FileSystemProviding, pathsManager: PathsProviding, fileEditor: FileEditingProvider) throws {
        self.fileSystemManager = fileSystemManager
        self.pathsManager = pathsManager
        self.fileEditor = fileEditor
    }
}

final class DependencyManager {
    static let shared = DependencyManager()
    
    var dependencyProvider: DependencyProviding
    
    private init() {
        do {
            try dependencyProvider = DependencyProvider()
        } catch (let error) {
            fatalError(error.localizedDescription)
        }
    }
}

extension DependencyManager: DependencyProviding {
    var fileSystemManager: any FileSystemProviding {
        dependencyProvider.fileSystemManager
    }
    
    var pathsManager: any PathsProviding {
        dependencyProvider.pathsManager
    }
    
    var fileEditor: any FileEditingProvider {
        dependencyProvider.fileEditor
    }
}
