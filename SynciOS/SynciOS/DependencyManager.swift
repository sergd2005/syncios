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
    var gitProviding: GitProviding { get }
    var storageCoordinationProviding: StorageCoordinationProviding { get }
}

final class DefaultDependencyProvider: DependencyProviding {
    let fileSystemManager: FileSystemProviding
    let pathsManager: PathsProviding
    let fileEditor: FileEditingProvider
    let gitProviding: GitProviding
    let storageCoordinationProviding: StorageCoordinationProviding
    
    init() {
        pathsManager = PathsManager()
        storageCoordinationProviding = StorageCoordinator()
        do {
            fileSystemManager = try FileSystemManager(folderURL: pathsManager.localURL)
            gitProviding = try GitFileSystem()
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
    let gitProviding: GitProviding
    let storageCoordinationProviding: StorageCoordinationProviding
    
    init(fileSystemManager: FileSystemProviding, pathsManager: PathsProviding, fileEditor: FileEditingProvider) throws {
        self.fileSystemManager = fileSystemManager
        self.pathsManager = pathsManager
        self.fileEditor = fileEditor
        // TODO: init with mock
        self.storageCoordinationProviding = StorageCoordinator()
        do {
            // TODO: init with mock
            gitProviding = try GitFileSystem()
        } catch (let error) {
            fatalError(error.localizedDescription)
        }
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
    
    var gitProviding: any GitProviding {
        dependencyProvider.gitProviding
    }
    
    var fileSystemManager: any FileSystemProviding {
        dependencyProvider.fileSystemManager
    }
    
    var pathsManager: any PathsProviding {
        dependencyProvider.pathsManager
    }
    
    var fileEditor: any FileEditingProvider {
        dependencyProvider.fileEditor
    }
    
    var storageCoordinationProviding: any StorageCoordinationProviding {
        dependencyProvider.storageCoordinationProviding
    }
}
