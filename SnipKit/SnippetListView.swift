//
//  SnippetList.swift
//  SnipKit
//
//  Created by Anssi Keinänen on 12.6.2026.
//

import SwiftUI
import SwiftData

struct SnippetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var snippets: [Snippet]
    @Query private var allSnippets: [Snippet]
    @Binding var selection: Snippet?
    @Binding var searchText: String
    @Binding var language: String?
    @Binding var folder: Folder?
    @Binding var tag: Tag?

    init(selection: Binding<Snippet?>,
         searchText: Binding<String>,
         language: Binding<String?>,
         folder: Binding<Folder?>,
         tag: Binding<Tag?>) {
        _selection = selection
        _searchText = searchText
        _language = language
        _folder = folder
        _tag = tag
        let text = searchText.wrappedValue
        let langValue = language.wrappedValue ?? ""
        let langActive = language.wrappedValue != nil
        _snippets = Query(filter: #Predicate<Snippet> { snippet in
            (text.isEmpty
                || snippet.title.localizedStandardContains(text)
                || snippet.code.localizedStandardContains(text)
                || snippet.language.localizedStandardContains(text))
            && (!langActive || snippet.language == langValue)
        }, sort: \.createdAt, order: .reverse)
    }

    private var availableLanguages: [String] {
        Array(Set(allSnippets.map(\.language))).sorted()
    }

    private var visibleSnippets: [Snippet] {
        snippets.filter { snippet in
            if let folder, folder.name != "All snippets", snippet.folder != folder { return false }
            if let tag, tag.name != "All tags", !snippet.tags.contains(where: { $0 == tag }) { return false }
            return true
        }
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(visibleSnippets) { snippet in
                Text(snippet.title)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(snippet)
                        }
                    }
                    .tag(snippet)
            }
        }
        .searchable(text: $searchText, placement: .toolbar)
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("All Languages") { language = nil }
                    if !availableLanguages.isEmpty {
                        Divider()
                        ForEach(availableLanguages, id: \.self) { lang in
                            Button {
                                language = lang
                            } label: {
                                if language == lang {
                                    Label(lang, systemImage: "checkmark")
                                } else {
                                    Text(lang)
                                }
                            }
                        }
                    }
                } label: {
                    Label(language ?? "All Languages",
                          systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

#Preview {
    SnippetListView(selection: .constant(nil),
                searchText: .constant(""),
                language: .constant(nil),
                folder: .constant(nil),
                tag: .constant(nil))
        .modelContainer(for: Snippet.self, inMemory: true)
}
