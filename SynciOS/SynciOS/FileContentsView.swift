//
//  FileContentsView.swift
//  SynciOS
//
//  Created by Sergii D on 2/2/25.
//
import SwiftUI

struct FileContentsView: View {
    @State private var saving: Bool = false
    @ObservedObject private var fileContentsViewModel: FileContentsViewModel
    
    init(fileContentsViewModel: FileContentsViewModel) {
        self.fileContentsViewModel = fileContentsViewModel
    }
    
    var body: some View {
        ZStack {
            VStack {
                TextField(
                    "Contents",
                    text: $fileContentsViewModel.contents
                )
                Spacer()
            }
            if saving {
                ProgressView("Saving")
            }
        }
        .padding()
        .navigationTitle(fileContentsViewModel.name)
        .toolbar {
            if fileContentsViewModel.modified {
                Button("Save") {
                    saving = true
                    Task {
                        try await fileContentsViewModel.note.save()
                        saving = false
                    }
                }
            }
        }
        .onDisappear {
            Task {
                try await fileContentsViewModel.note.close()
            }
        }
    }
}

#Preview {
    NavigationView {
        FileContentsView(fileContentsViewModel: FileContentsViewModel(note: Note(name: "Preview.json", editor: DependencyManager.shared.fileEditor)))
    }
}
