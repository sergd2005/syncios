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
    @Test func fetchAllFiles() async throws {
        let context = DependencyManager.shared.coreDataStack.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: FileSystemIncrementalStore.EntityType.file.rawValue)
        let result = try? context.fetch(fetchRequest) as? [SIFile]
        #expect(result != nil)
        print(result!)
    }
}
