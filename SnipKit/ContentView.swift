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
    @State private var selectedSnippet: Snippet?
    @State private var searchText: String = ""
    @State private var languageFilter: String?
    
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
            SnippetList(selection: $selectedSnippet,
                        searchText: $searchText,
                        language: $languageFilter)
        } detail: {
            switch selectedSnippet {
            case .some(let s):
                @Bindable var snippet = s
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Untitled Snippet", text: $snippet.title)
                        .textFieldStyle(.plain)
                        .font(.largeTitle.weight(.semibold))
                        .lineLimit(1)

                    Divider()

                    TextEditor(text: $snippet.code)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .overlay(
                            alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                            }
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .frame(maxWidth: .infinity, minHeight: 300)

                    HStack(spacing: 6) {
                        Label("Language", systemImage: "chevron.left.forwardslash.chevron.right")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(.secondary)
                        TextField("plaintext", text: $snippet.language)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
