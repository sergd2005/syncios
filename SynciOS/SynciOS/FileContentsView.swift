//
//  FileContentsView.swift
//  SynciOS
//
//  Created by Sergii D on 2/2/25.
//
import SwiftUI

struct FileContentsView: View {
    @State private var saving: Bool = false
    @ObservedObject private var viewModel: FileContentsViewModel
    
    init(fileContentsViewModel: FileContentsViewModel) {
        self.viewModel = fileContentsViewModel
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                if viewModel.isInConflict {
                    Text("Merge \"Contents\" field")
                }
                HStack {
                    Text(viewModel.isInConflict ? "Current:" : "Contents:")
                    TextField("", text: $viewModel.contents)
                            .textFieldStyle(.roundedBorder)
                            .disabled(viewModel.isInConflict)
                    if viewModel.isInConflict {
                        Button("✅") {
                            viewModel.note.resolveWithCurrent()
                        }
                    }
                }
                if viewModel.isInConflict {
                    if viewModel.isTwoWayConflict {
                        HStack {
                            Text("Current On Disk:")
                            TextField("", text: $viewModel.contentsOnDisk)
                                .textFieldStyle(.roundedBorder)
                                .disabled(true)
                            Button("✅") {
                                viewModel.note.resolveWithCurrentOnDisk()
                            }
                        }
                    }
                    HStack {
                        Text(viewModel.isTwoWayConflict ? "Incoming On Disk:" : "Incoming:")
                        TextField("", text: $viewModel.incomingContents)
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        Button("✅") {
                            viewModel.note.resolveWithIncoming()
                        }
                    }
                }
                Spacer()
            }
            if saving {
                ProgressView("Saving")
            }
        }
        .padding()
        .navigationTitle(viewModel.name)
        .toolbar {
            if viewModel.modified {
                Button("Save") {
                    viewModel.save()
                }
            }
            Button("Sync") {
                Task {
                    try await DependencyManager.shared.storageCoordinationProviding.sync()
                }
            }
        }
        .onAppear {
            viewModel.read()
        }
        .onDisappear {
            viewModel.unload()
        }
    }
}

#Preview {
    NavigationView {
        FileContentsView(fileContentsViewModel: FileContentsViewModel(note: Note(name: "Preview.json",
                                                                                 fileStorage: SIFileStorage(),
                                                                                 editor: DependencyManager.shared.fileEditor)))
    }
}
