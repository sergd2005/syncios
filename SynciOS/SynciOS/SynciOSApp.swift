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
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localUrl = documentsDirectory.appendingPathComponent("repo")
        let repoGitFolderPath = localUrl.path + "/.git"
        print(repoGitFolderPath)
        guard let remoteUrl = URL(string: "https://github.com/sergd2005/syncdata.git") else {
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
            case .success(let commit):
                print(commit)
            case .failure(let error):
                print(error)
            }
            let remoteResult = repo.remote(named: "origin")
            switch remoteResult {
            case .success(let remote):
                let fetchResult = repo.fetch(remote)
                switch fetchResult {
                case .success():
                    print("merge result: \(repo.merge(commit: "26be6a1"))")
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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
}
