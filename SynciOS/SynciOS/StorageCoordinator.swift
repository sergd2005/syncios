//
//  StorageCoordinator.swift
//  SynciOS
//
//  Created by Sergii D on 2/3/25.
//

protocol StorageCoordinationProviding {
    func sync() async throws
    func commit(message: String) async throws
}

final class StorageCoordinator: StorageCoordinationProviding {
    
    func sync() async throws {
//        try await DependencyManager.shared.gitProviding.syncData()
        for file in await DependencyManager.shared.fileEditor.files(with: .read) {
            try await file.read()
        }
        for file in await DependencyManager.shared.fileEditor.files(with: .saved) {
            try await file.read()
        }
        for file in await DependencyManager.shared.fileEditor.files(with: .modified) {
            try await file.read()
        }
    }
    
    func commit(message: String) async throws {
        _ = try await DependencyManager.shared.gitProviding.commit(message: message)
    }
}
