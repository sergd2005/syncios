//
//  SynciOSApp.swift
//  SynciOS
//
//  Created by Sergii D on 1/25/25.
//

import SwiftUI

import CoreData

@main
struct SynciOSApp: App {
    
    init()  {
        let pathsManager = MockPathsManager(localURL: URL(string: "file:///Users/sergiid/Desktop/data/syncdata/")!)
        let fileEditor = FileEditor()
        guard let fileSystemManager = try? FileSystemManager(folderURL: pathsManager.localURL),
        let dependencyProvider = try? MockDependencyProvider(fileSystemManager: fileSystemManager, pathsManager: pathsManager, fileEditor: fileEditor) else { fatalError() }
        DependencyManager.shared.dependencyProvider = dependencyProvider
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
