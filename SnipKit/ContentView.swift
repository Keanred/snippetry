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
    @State private var folderSelection: Folder?
    @State private var tagSelection: Tag?
    @State private var isTagSheetPresented: Bool = false
    @State private var editingTag: Tag?

    var body: some View {
        NavigationSplitView {
            SidebarView(folderSelection: $folderSelection,
                        tagSelection: $tagSelection,
                        onAddTag: presentNewTagSheet,
                        onEditTag: presentEditTagSheet,
                        onAddSnippet: addSnippet)
                .sheet(isPresented: $isTagSheetPresented) {
                    TagEditorSheet(editingTag: editingTag)
                }
        } content: {
            SnippetListView(selection: $selectedSnippet,
                            searchText: $searchText,
                            language: $languageFilter,
                            folder: $folderSelection,
                            tag: $tagSelection)
        } detail: {
            if let snippet = selectedSnippet {
                SnippetDetailView(snippet: snippet)
            } else {
                Text("Select a snippet")
            }
        }
    }

    private func presentNewTagSheet() {
        editingTag = nil
        isTagSheetPresented = true
    }

    private func presentEditTagSheet(_ tag: Tag) {
        editingTag = tag
        isTagSheetPresented = true
    }

    private func addSnippet() {
        withAnimation {
            modelContext.insert(Snippet(title: "New Snippet", code: ""))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Snippet.self, inMemory: true)
}
