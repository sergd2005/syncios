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

final class DefaultDependencyProvider: DependencyProviding {
    let fileSystemManager: FileSystemProviding
    let pathsManager: PathsProviding
    let fileEditor: FileEditingProvider
    
    init() {
        pathsManager = PathsManager()
        do {
            fileSystemManager = try FileSystemManager(folderURL: pathsManager.localURL)
        } catch (let error) {
            fatalError(error.localizedDescription)
        }
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
    
    init(dependencyProvider: DependencyProviding = DefaultDependencyProvider()) {
        self.dependencyProvider = dependencyProvider
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
