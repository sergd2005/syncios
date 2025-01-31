//
//  CoreDataStack.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//
import CoreData

protocol CoreDataStackProviding {
    var persistentContainer: NSPersistentContainer { get }
}

class CoreDataStack: ObservableObject, CoreDataStackProviding {
    
    private let pathsManager: PathsProviding
    
    init(pathsManager: PathsProviding) {
        self.pathsManager = pathsManager
        NSPersistentStoreCoordinator.registerStoreClass(FileSystemIncrementalStore.self, type: FileSystemIncrementalStore.type)
    }
    
    private lazy var storeDescription: NSPersistentStoreDescription = {
        let desc = NSPersistentStoreDescription(url: pathsManager.localURL)
        desc.type = FileSystemIncrementalStore.type.rawValue
        return desc
    }()
    
    // Create a persistent container as a lazy variable to defer instantiation until its first use.
    lazy var persistentContainer: NSPersistentContainer = {
        
        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentContainer(name: "Model")
        container.persistentStoreDescriptions = [storeDescription]
        
        // Load any persistent stores, which creates a store if none exists.
        container.loadPersistentStores { description, error in
            if let error {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
}
