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
        let repoFolderPath = NSHomeDirectory()+"/repo"
        let repoGitFolderPath = repoFolderPath + "/.git"
        
        guard let remoteUrl = URL(string: "https://github.com/sergd2005/syncdata.git"),
              let localUrl = URL(string: repoFolderPath) else {
            print("urls creation failed")
            return
        }

        var result: Result<Repository, NSError>?
        if FileManager.default.fileExists(atPath: repoGitFolderPath) {
            result = Repository.at(localUrl)
        } else {
            result = Repository.clone(from: remoteUrl, to: localUrl)
        }
        
        guard let result else { return }
        
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
