//
//  SnippetList.swift
//  SnipKit
//
//  Created by Anssi Keinänen on 12.6.2026.
//

import SwiftUI
import SwiftData

struct SnippetList: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var snippets: [Snippet]
    @Query private var allSnippets: [Snippet]
    @Binding var selection: Snippet?
    @Binding var searchText: String
    @Binding var language: String?

    init(selection: Binding<Snippet?>, searchText: Binding<String>, language: Binding<String?>) {
        _selection = selection
        _searchText = searchText
        _language = language
        let text = searchText.wrappedValue
        _snippets = Query(filter: #Predicate { snippet in
            text.isEmpty
                || snippet.title.localizedStandardContains(text)
                || snippet.code.localizedStandardContains(text)
                || snippet.language.localizedStandardContains(text)
        }, sort: \.createdAt, order: .reverse)
    }

    private var availableLanguages: [String] {
        Array(Set(allSnippets.map(\.language))).sorted()
    }

    private var filteredSnippets: [Snippet] {
        guard let language else { return snippets }
        return snippets.filter { $0.language == language }
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(filteredSnippets) { snippet in
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
    SnippetList(selection: .constant(nil),
                searchText: .constant(""),
                language: .constant(nil))
        .modelContainer(for: Snippet.self, inMemory: true)
}
