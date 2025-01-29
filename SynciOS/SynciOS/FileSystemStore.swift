//
//  FileSystemStore.swift
//  SynciOS
//
//  Created by Sergii D on 1/27/25.
//

import CoreData
import SwiftGit2

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

enum FileSystemManagerError: Error {
    case fileExists
    case failedToParseObject
    case fileEmpty
}

final class FileSystemManager {
    private let folderURL: URL
    
    init(folderURL: URL) {
        self.folderURL = folderURL
    }
    
    func allFileNames() throws -> [String] {
        guard let dirEnum = FileManager.default.enumerator(atPath: folderURL.path) else {
            return []
        }
        var result = [String]()
        while let file = dirEnum.nextObject() as? String {
            if file.hasSuffix(".json") {
                result.append(file)
            }
        }
        return result
    }
    
    func parseJSONFile(name: String) throws -> [String: Any] {
        guard let result = try JSONSerialization.jsonObject(with: try NSData(contentsOfFile: folderURL.path + "/" + name) as Data) as? [String: Any]
        else {
            throw FileSystemManagerError.failedToParseObject
        }
        guard !result.isEmpty else { throw FileSystemManagerError.fileEmpty }
        return result
    }
    
    func writeFile(name: String, data: [String: Any]) throws {
        let filePath = folderURL.path + "/" + name + ".json"
        guard !FileManager.default.fileExists(atPath: filePath) else { throw FileSystemManagerError.fileExists }
        try (JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) as NSData).write(toFile: filePath)
    }
}

enum GitFileSystemError: Error {
    case repositoryIsNotInitialised
    case fileNotFound
    case failedToPush
}

final class GitFileSystem {
    private let folderURL: URL
    private var repo: Repository?
    
    init(folderURL: URL) {
        self.folderURL = folderURL
    }
    
    func fetchLatestData() {
        let repoGitFolderPath = folderURL.path + "/.git"
        print(repoGitFolderPath)
        guard let remoteUrl = URL(string: "https://github.com/sergd2005/syncdata.git") else {
            print("urls creation failed")
            return
        }

        var result: Result<Repository, NSError>?
        if FileManager.default.fileExists(atPath: repoGitFolderPath) {
            result = Repository.at(folderURL)
        } else {
            result = Repository.clone(from: remoteUrl, to: folderURL)
        }
        
        guard let result else { return }
        
        switch result {
        case let .success(repo):
            self.repo = repo
            let remoteResult = repo.remote(named: "origin")
            switch remoteResult {
            case .success(let remote):
                let fetchResult = repo.fetch(remote)
                switch fetchResult {
                case .success():
                    let remoteBranchResult = repo.remoteBranch(named: "origin/main")
                    switch remoteBranchResult {
                    case .success(let remoteBranch):
                        var mergeResult = repo.merge(commit: "\(remoteBranch.oid)")
                        while mergeResult != 0 {
                            switch mergeResult {
                                // TODO: create enum of merge state in Swift
                                // Merge state
                            case 1:
                                do {
                                    let commit = try commit(message: "Merge main")
                                    print("Merge commit created: \(commit)")
                                } catch(let error) {
                                    print(error)
                                    return
                                }
                            default:
                                ()
                            }
                            mergeResult = repo.merge(commit: "\(remoteBranch.oid)")
                        }
                        print("Pushed :\(repo.push())")
                        let latestCommit = repo
                            .HEAD()
                            .flatMap {
                                repo.commit($0.oid)
                            }
                        switch latestCommit {
                        case .success(let commit):
                            print(commit)
                        case .failure(let error):
                            print(error)
                        }
                    case .failure(let error):
                        print(error)
                    }

                case .failure(let error):
                    print(error)
                }
            case .failure(let error):
                print(error)
            }
        case let .failure(error):
            print("Could not open repository: \(error)")
        }
    }
    
    // TODO: stage by file name - use git_index_add_bypath
    func add(name: String) throws {
        let filePath = "/"
        guard let repo else { throw GitFileSystemError.repositoryIsNotInitialised }
        let addResult = repo.add(path: filePath)
        switch addResult {
        case .success():
            ()
        case .failure(let error):
            throw error
        }
    }
    
    func commit(message: String) throws -> Commit {
        guard let repo else { throw GitFileSystemError.repositoryIsNotInitialised }
        let commitResult = repo.commit(message: message, signature: Signature(name: "test", email: "test@test.com"))
        switch commitResult {
        case .success(let newCommit):
            return newCommit
        case .failure(let error):
            throw error
        }
    }
    
    func push() throws {
        guard let repo else { throw GitFileSystemError.repositoryIsNotInitialised }
        guard repo.push() == 0 else { throw GitFileSystemError.failedToPush }
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
    private var gitFileSystem: GitFileSystem?
    
    enum EntityType: String {
        case file = "SIFile"
    }
    
    private let uuid = UUID()
    
    static var type: NSPersistentStore.StoreType {
        // TODO: get module name for store type
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
            throw FileSystemIncrementalStoreError.invalidUrl
        }
        let metadata = [NSStoreUUIDKey : uuid.uuidString, NSStoreTypeKey: Self.type.rawValue]
        self.metadata = metadata
        fileSystemManager = FileSystemManager(folderURL: storeURL)
        gitFileSystem = GitFileSystem(folderURL: storeURL)
    }
    
    override func execute(_ request: NSPersistentStoreRequest, with context: NSManagedObjectContext?) throws -> Any {
        guard let fileSystemManager, let gitFileSystem else { throw FileSystemIncrementalStoreError.fileSystemNotInitialised }
        switch request.requestType {
        case .fetchRequestType:
            guard let context else { throw FileSystemIncrementalStoreError.noContext }
            guard let fetchRequest = request as? NSFetchRequest<NSManagedObject> else { throw FileSystemIncrementalStoreError.invalidFetchRequest }
            guard let entity = fetchRequest.entity else { throw FileSystemIncrementalStoreError.invalidFetchRequestEntity }
            guard let entityName = entity.name else { throw FileSystemIncrementalStoreError.emptyEntityName }
            guard let entityType = EntityType(rawValue: entityName) else { throw FileSystemIncrementalStoreError.undefinedEntityType }
            
            gitFileSystem.fetchLatestData()
            
            switch entityType {
            case .file:
                let fileNames = try fileSystemManager.allFileNames()
                var fetchedObjects = [NSManagedObject]()
                for fileName in fileNames {
                    let objectID = self.newObjectID(for: entity, referenceObject: fileName)
                    var managedObject = context.object(with: objectID)
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
                        try fileSystemManager.writeFile(name: sifileName, data: ["name" : sifileName,
                                                                                "contents" : sifile.contents ?? ""
                                                                                ])
                        try gitFileSystem.add(name: sifileName)
                        try gitFileSystem.commit(message: "Adding \(sifileName)")
                        gitFileSystem.fetchLatestData()
                        try gitFileSystem.push()
                    }
                }
            }
            if let updatedObjects = saveRequest.updatedObjects {
                
            }
            if let deletedObjects = saveRequest.deletedObjects {
                
            }
            if let optLockObjects = saveRequest.lockedObjects {
                
            }
            
            return [AnyObject]()
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
    
    // MARK: Fulfilling Attribute Faults
    override func newValuesForObject(with objectID: NSManagedObjectID, with context: NSManagedObjectContext) throws -> NSIncrementalStoreNode {
        guard let uid = referenceObject(for: objectID) as? String else {
            throw FileSystemIncrementalStoreError.wrongObjectID
        }
        guard let fileSystemManager else { throw FileSystemIncrementalStoreError.fileSystemNotInitialised  }
        let jsonDict = try? fileSystemManager.parseJSONFile(name: uid)
        return NSIncrementalStoreNode(objectID: objectID, withValues: jsonDict ?? ["name": uid], version: 0)
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

