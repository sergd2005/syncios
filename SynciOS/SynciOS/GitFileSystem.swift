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

protocol GitProviding {
    func syncData() async throws
    func commit(message: String) async throws -> Commit
}

final class GitFileSystem: GitProviding {
    private var repo: Repository?
    
    init() throws {
        CredsStorage.login = "sergd2005"
        CredsStorage.token = "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"
    }
    
    func syncData() async throws {
        if repo == nil {
            repo = try initRepo()
        }
        try await mergePush()
    }
    
    private func initRepo() throws -> Repository {
        let folderURL = DependencyManager.shared.pathsManager.localURL
        let repoGitFolderPath = folderURL.path + "/.git"
        print(repoGitFolderPath)
        
        guard let remoteUrl = URL(string: "https://github.com/sergd2005/syncdata.git") else {
            throw GitFileSystemError.repositoryIsNotInitialised
        }

        var result: Result<Repository, NSError>?
        if FileManager.default.fileExists(atPath: repoGitFolderPath) {
            result = Repository.at(folderURL)
        } else {
            result = Repository.clone(from: remoteUrl, to: folderURL)
        }
        
        guard let result else { throw GitFileSystemError.repositoryIsNotInitialised }
        
        switch result {
        case let .success(repo):
            return repo
        case .failure(_):
            throw GitFileSystemError.repositoryIsNotInitialised
        }
    }
    
    private func mergePush() async throws {
        guard let repo else { throw GitFileSystemError.repositoryIsNotInitialised }
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
                    switch mergeResult {
                    case 0:
                        // conflict?
                        ()
                    case 1:
                        // merge resolved need commit and push
                        _ = try await commit(message: "Merge commit \(Date())")
//                        print("Pushed :\(repo.push())")
                    default:
                        ()
                    }
                    print("Pushed :\(repo.push())")
//                    let latestCommit = repo
//                        .HEAD()
//                        .flatMap {
//                            repo.commit($0.oid)
//                        }
//                    switch latestCommit {
//                    case .success(let commit):
//                        print(commit)
//                    case .failure(let error):
//                        throw error
//                    }
                case .failure(let error):
                    throw error
                }

            case .failure(let error):
                throw error
            }
        case .failure(let error):
            throw error
        }
    }
    
    // TODO: stage by file name - use git_index_add_bypath
    private func add(name: String) throws {
        guard let repo else { throw GitFileSystemError.repositoryIsNotInitialised }
        let filePath = "/"
        let addResult = repo.add(path: filePath)
        switch addResult {
        case .success():
            ()
        case .failure(let error):
            throw error
        }
    }
    
    func commit(message: String) async throws -> Commit {
        try add(name: "")
        guard let repo else { throw GitFileSystemError.repositoryIsNotInitialised }
        let commitResult = repo.commit(message: message, signature: Signature(name: "test", email: "test@test.com"))
        switch commitResult {
        case .success(let newCommit):
            return newCommit
        case .failure(let error):
            throw error
        }
    }
}
