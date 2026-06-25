//
//  ContentView.swift
//  Snippetry
//
//  Created by Anssi Keinänen on 10.6.2026.
//

import SwiftUI
import SwiftData
import AppKit
import KeyboardShortcuts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @AppStorage("defaultLanguage") private var defaultLanguage: String = "plaintext"
    @State private var selectedSnippet: Snippet?
    @State private var searchText: String = ""
    @State private var languageFilter: String?
    @State private var folderSelection: Folder?
    @State private var tagSelection: Tag?
    @State private var isTagSheetPresented: Bool = false
    @State private var editingTag: Tag?
    @State private var isHelpPresented: Bool = false

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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    isHelpPresented.toggle()
                } label: {
                    Label("Shortcuts", systemImage: "questionmark.circle")
                }
                .help("Keyboard shortcuts")
                .popover(isPresented: $isHelpPresented, arrowEdge: .bottom) {
                    ShortcutsHelpView()
                }
            }
        }
        .onChange(of: appState.commandID) { _, _ in
            handle(appState.lastCommand)
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

    private func handle(_ command: Command?) {
        guard let command else { return }
        switch command {
        case .new: addSnippet()
        case .copy: copySelection()
        case .duplicate: duplicateSelection()
        case .delete: deleteSelection()
        case .focusSearch: break
        }
    }

    private func addSnippet() {
        let snippet = Snippet(title: "New Snippet", code: "", language: defaultLanguage)
        withAnimation {
            modelContext.insert(snippet)
            selectedSnippet = snippet
        }
    }

    private func copySelection() {
        guard let snippet = selectedSnippet else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(snippet.code, forType: .string)
    }

    private func duplicateSelection() {
        guard let snippet = selectedSnippet else { return }
        let copy = Snippet(
            title: snippet.title.isEmpty ? "Untitled Copy" : "\(snippet.title) Copy",
            code: snippet.code,
            language: snippet.language
        )
        copy.folder = snippet.folder
        copy.tags = snippet.tags
        withAnimation {
            modelContext.insert(copy)
            selectedSnippet = copy
        }
    }

    private func deleteSelection() {
        guard let snippet = selectedSnippet else { return }
        withAnimation {
            modelContext.delete(snippet)
            selectedSnippet = nil
        }
    }
}

private struct ShortcutsHelpView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Shortcuts")
                .font(.headline)
            HStack {
                Text("Toggle picker")
                Spacer(minLength: 16)
                Text(KeyboardShortcuts.getShortcut(for: .togglePicker)?.description ?? "Not set")
                    .foregroundStyle(.secondary)
                    .monospaced()
            }
            Divider()
            Button("Change in Settings…") {
                openSettings()
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: Snippet.self, inMemory: true)
}
