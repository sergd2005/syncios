//
//  SynciOSTests.swift
//  SynciOSTests
//
//  Created by Sergii D on 1/25/25.
//

import Testing
@testable import SynciOS
import CoreData

struct CoreDataStackTests {
    let pathsManager = PathsManager()
    let coreDataStack: CoreDataStack
    
    init() {
        coreDataStack = CoreDataStack(pathsManager: pathsManager)
    }
    
    @Test func fetchAllFiles() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        print(pathsManager.localURL)
        let context = coreDataStack.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: FileSystemIncrementalStore.EntityType.file.rawValue)
        let result = try? context.fetch(fetchRequest) as? [SIFile]
        #expect(result != nil)
        print(result!)
    }

}
