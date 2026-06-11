//
//  ContentView.swift
//  SnipKit
//
//  Created by Anssi Keinänen on 10.6.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Snippet.createdAt, order: .reverse) private var snippets: [Snippet]
    @State private var selectedSnippet: Snippet?

    var body: some View {
        NavigationSplitView {
            List {
                Section("LIBRARY") {
                    Text("All snippets")
                    Text("Favorites")
                    Text("Trash")
                }
                Section("TAGS") {
                    Text("#SwiftUI")
                    Text("#Swift")
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addSnippet) {
                        Label("Add snippet", systemImage: "plus")
                    }
                }
            }
        } content: {
            List(selection: $selectedSnippet) {
                ForEach(snippets) { snippet in
                    Text(snippet.title).contextMenu {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(snippet)
                        }
                    }.tag(snippet)
                }
            }
        } detail: {
            switch selectedSnippet {
            case .some(let s):
                @Bindable var snippet = s
                TextField("Title", text: $snippet.title)
                TextField("Code", text: $snippet.code)
                TextField("Language", text: $snippet.language)
            case .none:
                Text("Select a snippet")
            }
        }
    }

    private func addSnippet() {
        withAnimation {
            let newItem = Snippet(title: "New Snippet", code: "")
            modelContext.insert(newItem)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Snippet.self, inMemory: true)
}
