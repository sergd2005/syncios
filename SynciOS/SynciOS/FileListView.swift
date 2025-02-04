//
//  ContentView.swift
//  SynciOS
//
//  Created by Sergii D on 1/25/25.
//

import SwiftUI
import CoreData

struct FileListView: View {
    @State var noteViewModels: [FileListViewModel] = []
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(noteViewModels) { noteViewModel in
                    NavigationLink(destination: FileContentsView(fileContentsViewModel: FileContentsViewModel(note: noteViewModel.note))) {
                        HStack {
                            Text(noteViewModel.name)
                            Button(action: {
                                Task {
                                    do {
                                        _ = try await DependencyManager.shared.fileEditor.deleteFile(noteViewModel.note)
                                        refreshFiles()
                                    } catch(let error) {
                                        print(error)
                                    }
                                }
                            }) {
                                Label("",systemImage: "trash")
                                    .tint(.red)
                            }
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .navigationTitle("Files")
            .toolbar {
                Button("Add") {
                    Task {
                        _ = try await DependencyManager.shared.fileEditor.createFile(name: "New File.json") as Note
                        refreshFiles()
                    }
                }
            }
        }
        .onAppear() {
            refreshFiles()
        }
    }
    
    func refreshFiles() {
        Task {
            try await DependencyManager.shared.storageCoordinationProviding.sync()
            noteViewModels.removeAll()
            for filename in try DependencyManager.shared.fileEditor.allFileNames() {
                noteViewModels.append(FileListViewModel(note: try await DependencyManager.shared.fileEditor.openFile(name: filename)))
            }
        }
    }
}

#Preview {
    FileListView()
}
