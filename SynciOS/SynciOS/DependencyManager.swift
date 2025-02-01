//
//  DependencyManager.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//

protocol DependencyProviding {
    var fileSystemManager: FileSystemProviding { get }
    var pathsManager: PathsProviding { get }
    var coreDataStack: CoreDataStack { get }
}

final class DependencyProvider: DependencyProviding {
    let fileSystemManager: FileSystemProviding
    let pathsManager: PathsProviding
    let coreDataStack: CoreDataStack
    
    init() throws {
        pathsManager = PathsManager()
        fileSystemManager = try FileSystemManager(folderURL: pathsManager.localURL)
        coreDataStack = CoreDataStack(pathsManager: pathsManager)
    }
}

final class DependencyManager {
    static let shared = DependencyManager()
    
    var dependencyProvider: DependencyProviding
    
    private init() {
        do {
            try dependencyProvider = DependencyProvider()
        } catch (let error) {
            print(error)
            fatalError()
        }
    }
}

extension DependencyManager: DependencyProviding {
    var coreDataStack: CoreDataStack {
        dependencyProvider.coreDataStack
    }
    
    var fileSystemManager: any FileSystemProviding {
        dependencyProvider.fileSystemManager
    }
    
    var pathsManager: any PathsProviding {
        dependencyProvider.pathsManager
    }
}
