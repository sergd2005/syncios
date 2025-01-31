//
//  ContentView.swift
//  SynciOS
//
//  Created by Sergii D on 1/25/25.
//

import SwiftUI
import CoreData

struct FileViewModel: Identifiable {
    let name: String
    let contents: String
    var id: String { name }
}

struct FileContentsView: View {
    let fileViewModel: FileViewModel
    
    var body: some View {
        VStack {
            Text(fileViewModel.contents)
        }
    }
}

struct ContentView: View {
    let coreDataStack: CoreDataStackProviding
    
    @State var files: [FileViewModel] = []
    
    init(coreDataStack: CoreDataStackProviding) {
        self.coreDataStack = coreDataStack
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(files) { file in
                    NavigationLink(destination: FileContentsView(fileViewModel: file)) {
                        Text(file.name)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .navigationTitle("Files")
            .toolbar {
                Button("Add") {
                    coreDataStack.persistentContainer.performBackgroundTask { context in
                        guard let _ = NSEntityDescription.insertNewObject(forEntityName: "SIFile", into: context) as? SIFile else {
                            print("[ERROR] Failed to insert object")
                            return
                        }
                        do {
                            try context.save()
                            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: FileSystemIncrementalStore.EntityType.file.rawValue)
                            let result = try? context.fetch(fetchRequest) as? [SIFile]
                            if let result {
                                files = result.map { FileViewModel(name: $0.name ?? "",
                                                                   contents: $0.contents ?? "") }
                            }
                        } catch(let error) {
                            print(error)
                        }
                    }
                }
            }
        }
        .onAppear() {
            coreDataStack.persistentContainer.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: FileSystemIncrementalStore.EntityType.file.rawValue)
                let result = try? context.fetch(fetchRequest) as? [SIFile]
                if let result {
                    files = result.map { FileViewModel(name: $0.name ?? "",
                                                       contents: $0.contents ?? "") }
                }
            }
        }
    }
}

#Preview {
    ContentView(coreDataStack: CoreDataStack(pathsManager: PathsManager()))
}

#Preview {
    FileContentsView(fileViewModel: FileViewModel(name: "Test", contents: "aadfadfadfasdfasdfasd"))
}
