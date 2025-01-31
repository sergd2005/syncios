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

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let files: [SIFile]
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: FileSystemIncrementalStore.EntityType.file.rawValue)
        let result = try? context.fetch(fetchRequest) as? [SIFile]
        #expect(result != nil)
        print(result!)
    }

}
