//
//  FileSystemStore.swift
//  SynciOS
//
//  Created by Sergii D on 1/27/25.
//

import CoreData

enum FileSystemIncrementalStoreError: Error {
    case invalidUrl
    case invalidFetchRequest
    case invalidSaveChangesRequest
    case invalidFetchRequestEntity
    case emptyEntityName
    case undefinedEntityType
    case fileSystemNotInitialised
    case noContext
    case wrongObjectID
    case failedToParseObject
    case wrongObject
    case fileNameIsNil
}

final class FileSystemIncrementalStore: NSIncrementalStore {
    private var fileSystemManager: FileSystemProviding?
    
    enum EntityType: String {
        case file = "SIFile"
    }
    
    private let uuid = UUID()
    
    static var type: NSPersistentStore.StoreType {
        // TODO: get module name for store type
        NSPersistentStore.StoreType(rawValue: "SynciOS.\(Self.self)")
    }
    
    // MARK: Init Store
    override func loadMetadata() throws {
        let metadata = [NSStoreUUIDKey : uuid.uuidString, NSStoreTypeKey: Self.type.rawValue]
        self.metadata = metadata
        fileSystemManager = DependencyManager.shared.fileSystemManager
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        guard let fileSystemManager else { throw FileSystemIncrementalStoreError.fileSystemNotInitialised }
        switch request.requestType {
        case .fetchRequestType:
            guard let context else { throw FileSystemIncrementalStoreError.noContext }
            guard let fetchRequest = request as? NSFetchRequest<NSManagedObject> else { throw FileSystemIncrementalStoreError.invalidFetchRequest }
            guard let entity = fetchRequest.entity else { throw FileSystemIncrementalStoreError.invalidFetchRequestEntity }
            guard let entityName = entity.name else { throw FileSystemIncrementalStoreError.emptyEntityName }
            guard let entityType = EntityType(rawValue: entityName) else { throw FileSystemIncrementalStoreError.undefinedEntityType }
            
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
            guard let saveRequest = request as? NSSaveChangesRequest else { throw FileSystemIncrementalStoreError.invalidSaveChangesRequest }
            if let insertedObjects = saveRequest.insertedObjects {
                for insertedObject in insertedObjects {
                    guard let entityName = insertedObject.entity.name else { throw FileSystemIncrementalStoreError.emptyEntityName }
                    guard let entityType = EntityType(rawValue: entityName) else { throw FileSystemIncrementalStoreError.undefinedEntityType }
                    switch entityType {
                    case .file:
                        guard let sifile = insertedObject as? SIFile else { throw FileSystemIncrementalStoreError.wrongObject }
                        guard let sifileName = sifile.name else { throw FileSystemIncrementalStoreError.fileNameIsNil }
                        try fileSystemManager.createFile(name: sifileName, data: try sifile.toData())
                    }
                }
            }
            if let updatedObjects = saveRequest.updatedObjects {
                for updatedObject in updatedObjects {
                    guard let entityName = updatedObject.entity.name else { throw FileSystemIncrementalStoreError.emptyEntityName }
                    guard let entityType = EntityType(rawValue: entityName) else { throw FileSystemIncrementalStoreError.undefinedEntityType }
                    switch entityType {
                    case .file:
                        guard let sifile = updatedObject as? SIFile else { throw FileSystemIncrementalStoreError.wrongObject }
                        guard let sifileName = sifile.name else { throw FileSystemIncrementalStoreError.fileNameIsNil }
                        try fileSystemManager.writeFile(name: sifileName, data: try sifile.toData())
                    }
                }
            }
            if let deletedObjects = saveRequest.deletedObjects {
                for deletedObject in deletedObjects {
                    guard let entityName = deletedObject.entity.name else { throw FileSystemIncrementalStoreError.emptyEntityName }
                    guard let entityType = EntityType(rawValue: entityName) else { throw FileSystemIncrementalStoreError.undefinedEntityType }
                    switch entityType {
                    case .file:
                        guard let sifile = deletedObject as? SIFile else { throw FileSystemIncrementalStoreError.wrongObject }
                        guard let sifileName = sifile.name else { throw FileSystemIncrementalStoreError.fileNameIsNil }
                        try fileSystemManager.deleteFile(name: sifileName)
                    }
                }
            }
            // TODO: support locked objects?
            if let optLockObjects = saveRequest.lockedObjects {
                fatalError()
            }
            
            return [AnyObject]()
            // TODO: support batch requests
//        case .batchInsertRequestType:
//            ()
//        case .batchUpdateRequestType:
//            ()
//        case .batchDeleteRequestType:
//            ()
        @unknown default:
            fatalError()
        }
    }
    
    // MARK: Fulfilling Attribute Faults
    override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let uid = referenceObject(for: objectID) as? String else {
            throw FileSystemIncrementalStoreError.wrongObjectID
        }
        guard let fileSystemManager else { throw FileSystemIncrementalStoreError.fileSystemNotInitialised  }
        let jsonDict = (try? fileSystemManager.parseJSONFile(name: uid)) ?? [:]
        var dataDict: [String: Any] = ["name": uid]
        for (key, value) in jsonDict {
            dataDict[key] = value
        }
        return NSIncrementalStoreNode(objectID: objectID, withValues: dataDict, version: 0)
    }
    
    // TODO: support relationships
    // TODO: separate contents into relationship object
    
    override func obtainPermanentIDs(for array: [NSManagedObject]) throws -> [NSManagedObjectID] {
        var result = [NSManagedObjectID]()
        for object in array {
            guard let entityName = object.entity.name else { throw FileSystemIncrementalStoreError.emptyEntityName }
            guard let entityType = EntityType(rawValue: entityName) else { throw FileSystemIncrementalStoreError.undefinedEntityType }
            switch entityType {
            case .file:
                guard let sifile = object as? SIFile else { throw FileSystemIncrementalStoreError.wrongObject }
                guard let sifileName = sifile.name else { throw FileSystemIncrementalStoreError.fileNameIsNil }
                result.append(self.newObjectID(for: sifile.entity, referenceObject: sifileName))
            }
        }
        return result
    }
}

