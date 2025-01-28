//
//  FileSystemStore.swift
//  SynciOS
//
//  Created by Sergii D on 1/27/25.
//

import CoreData

enum FileSystemStoreError: Error {
    case invalidUrl
    case invalidFetchRequest
    case invalidFetchRequestEntity
    case emptyEntityName
    case undefinedEntityType
    case fileSystemNotInitialised
    case noContext
}

final class FileSystemManager {
    private let folderURL: URL
    
    init(folderURL: URL) {
        self.folderURL = folderURL
    }
    
    func allFileNames() throws -> [String] {
        // TODO: Return actual contents of directory
        return ["test.json"]
    }
}

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    private init() {
        NSPersistentStoreCoordinator.registerStoreClass(FileSystemIncrementalStore.self, type: FileSystemIncrementalStore.type)
    }
    
    // Create a persistent container as a lazy variable to defer instantiation until its first use.
    lazy var persistentContainer: NSPersistentContainer = {
        
        // Pass the data model filename to the container’s initializer.
        let container = NSPersistentContainer(name: "Model")
        container.persistentStoreDescriptions = [FileSystemIncrementalStore.storeDescription]
        
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

final class FileSystemIncrementalStore: NSIncrementalStore {
    private var fileSystemManager: FileSystemManager?
    
    enum EntityType: String {
        case file = "SIFile"
    }
    
    private let uuid = UUID()
    
    static var type: NSPersistentStore.StoreType {
        NSPersistentStore.StoreType(rawValue: "SynciOS.\(Self.self)")
    }
    
    static let storeDescription: NSPersistentStoreDescription = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localUrl = documentsDirectory.appendingPathComponent("repo")
        let desc = NSPersistentStoreDescription(url: localUrl)
        desc.type = type.rawValue
        return desc
    }()
    
    // MARK: Init Store
    override func loadMetadata() throws {
        guard let storeURL = self.url else {
            throw FileSystemStoreError.invalidUrl
        }
        // TODO: get module name for store type
        let metadata = [NSStoreUUIDKey : uuid.uuidString, NSStoreTypeKey: Self.type.rawValue]
        self.metadata = metadata
        fileSystemManager = FileSystemManager(folderURL: storeURL)
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        guard let fileSystemManager else { throw FileSystemStoreError.fileSystemNotInitialised }
        switch request.requestType {
        case .fetchRequestType:
            guard let context else { throw FileSystemStoreError.noContext }
            guard let fetchRequest = request as? NSFetchRequest<NSManagedObject> else { throw FileSystemStoreError.invalidFetchRequest }
            guard let entity = fetchRequest.entity else { throw FileSystemStoreError.invalidFetchRequestEntity }
            guard let entityName = entity.name else { throw FileSystemStoreError.emptyEntityName }
            guard let entityType = EntityType(rawValue: entityName) else { throw FileSystemStoreError.undefinedEntityType }
            
            switch entityType {
            case .file:
                let fileNames = try fileSystemManager.allFileNames()
                var fetchedObjects = [NSManagedObject]()
                for fileName in fileNames {
                    let objectID = self.newObjectID(for: entity, referenceObject: fileName)
                    let managedObject = context.object(with: objectID)
                    fetchedObjects.append(managedObject)
                }
                return fetchedObjects
            }
            
        case .saveRequestType:
            ()
        case .batchInsertRequestType:
            ()
        case .batchUpdateRequestType:
            ()
        case .batchDeleteRequestType:
            ()
        @unknown default:
            fatalError()
        }
        return []
    }
}
