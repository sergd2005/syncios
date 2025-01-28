//
//  ContentView.swift
//  SynciOS
//
//  Created by Sergii D on 1/25/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear() {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: FileSystemIncrementalStore.EntityType.file.rawValue)
            let result = try? viewContext.fetch(fetchRequest) as? [SIFile]
            if let result {
                print(result)
            }
        }
    }
}

#Preview {
    ContentView()
}
