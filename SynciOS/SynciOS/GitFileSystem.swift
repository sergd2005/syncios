//
//  GitFileSystem.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//

import Foundation
import SwiftGit2

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
        CredsStorage.login = "sergd2005"
        CredsStorage.token = "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"
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
