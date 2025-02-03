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
            VStack {
                HStack {
                    Text("Contents")
                    //                    .frame(maxHeight: .infinity, alignment: .topLeading)
                    TextField("", text: $viewModel.contents)
                    //                    .frame(maxHeight: .infinity, alignment: .topLeading)
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
                    saving = true
                    Task {
                        try await viewModel.note.save()
                        saving = false
                    }
                }
            }
        }
        .onAppear {
            viewModel.didAppear()
        }
        .onDisappear {
            viewModel.didDisappear()
        }
    }
}

#Preview {
    NavigationView {
        FileContentsView(fileContentsViewModel: FileContentsViewModel(note: Note(name: "Preview.json", editor: DependencyManager.shared.fileEditor)))
    }
}
