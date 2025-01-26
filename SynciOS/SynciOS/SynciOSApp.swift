//
//  SynciOSApp.swift
//  SynciOS
//
//  Created by Sergii D on 1/25/25.
//

import SwiftUI
import SwiftGit2

@main
struct SynciOSApp: App {
    
    init() {
        let URL = URL(string: "")!
        let result = Repository.at(URL)
        switch result {
        case let .success(repo):
            let latestCommit = repo
                .HEAD()
                .flatMap {
                    repo.commit($0.oid)
                }

            switch latestCommit {
            case let .success(commit):
                print("Latest Commit: \(commit.message) by \(commit.author.name)")

            case let .failure(error):
                print("Could not get commit: \(error)")
            }

        case let .failure(error):
            print("Could not open repository: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}
