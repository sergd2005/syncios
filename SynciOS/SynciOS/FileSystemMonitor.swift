//
//  FileSystemMonitor.swift
//  SynciOS
//
//  Created by Sergii D on 1/31/25.
//
import Foundation

final class FileSystemMonitor {
    private var dirSource: (any DispatchSourceFileSystemObject)?
    
    init(name: String) throws {
        try start(name: name)
    }
    
    private func start(name: String) throws {
        let dirSource = try source(for: DependencyManager.shared.pathsManager.localURL.path + "/" + name)
        dirSource.setEventHandler { [weak self] in
            guard let self else { return }
            self.process(event: self.dirSource?.data)
        }
        dirSource.activate()
        self.dirSource = dirSource
    }
    
    private func process(event: DispatchSource.FileSystemEvent?) {
        guard let event else { return }
        print("Event recieved: \(event)")
        if event.contains(.write) {
            print("write event recieved: \(event)")
        }
        if event.contains(.all) {
            print("all event recieved: \(event)")
        }
        if event.contains(.attrib) {
            print("attrib event recieved: \(event)")
        }
        if event.contains(.delete) {
            print("delete event recieved: \(event)")
        }
        if event.contains(.extend) {
            print("extend event recieved: \(event)")
        }
        if event.contains(.funlock) {
            print("funlock event recieved: \(event)")
        }
        if event.contains(.link) {
            print("link event recieved: \(event)")
        }
        if event.contains(.revoke) {
            print("revoke event recieved: \(event)")
        }
    }
    
    private func source(for path: String) throws -> DispatchSourceFileSystemObject {
        let dirFD = open(path, O_EVTONLY)
        guard dirFD >= 0 else {
            let err = errno
            throw NSError(domain: POSIXError.errorDomain, code: Int(err), userInfo: nil)
        }
        return DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: dirFD,
            eventMask: [.all],
            queue: DispatchQueue.main
        )
    }
}
