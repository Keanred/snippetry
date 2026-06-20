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
    @Environment(AppState.self) private var appState
    @Query private var snippets: [Snippet]
    @Query private var allSnippets: [Snippet]
    @Binding var selection: Snippet?
    @Binding var searchText: String
    @Binding var language: String?
    @Binding var folder: Folder?
    @Binding var tag: Tag?
    @FocusState private var searchFocused: Bool

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
        VStack(spacing: 0) {
            searchField
            Divider()
            List(selection: $selection) {
                ForEach(visibleSnippets) { snippet in
                    SnippetRow(snippet: snippet)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        ))
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    modelContext.delete(snippet)
                                }
                            }
                        }
                        .tag(snippet)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: visibleSnippets.count)
        }
        .onChange(of: appState.focusSearchTrigger) { _, _ in
            searchFocused = true
        }
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

extension SnippetListView {
    fileprivate var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search title, code, or language", text: $searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

private struct SnippetRow: View {
    let snippet: Snippet

    private var subtitle: String {
        let firstLine = snippet.code
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? ""
        return firstLine.trimmingCharacters(in: .whitespaces)
    }

    private var relativeDate: String {
        snippet.createdAt.formatted(.relative(presentation: .named))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(snippet.title.isEmpty ? "Untitled" : snippet.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(relativeDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                LanguageBadge(language: snippet.language)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct LanguageBadge: View {
    let language: String

    private var label: String {
        let trimmed = language.trimmingCharacters(in: .whitespaces).lowercased()
        let known: [String: String] = [
            "javascript": "JS", "typescript": "TS", "python": "PY",
            "ruby": "RB", "swift": "SWI", "kotlin": "KT",
            "objective-c": "OBJ", "c++": "C++", "c#": "C#",
            "shell": "SH", "bash": "SH", "html": "HTM",
            "markdown": "MD", "plaintext": "TXT"
        ]
        if let m = known[trimmed] { return m }
        return String(trimmed.prefix(3)).uppercased()
    }

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.5)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
            )
            .foregroundStyle(Color.accentColor)
    }
}

#Preview {
    SnippetListView(selection: .constant(nil),
                searchText: .constant(""),
                language: .constant(nil),
                folder: .constant(nil),
                tag: .constant(nil))
        .environment(AppState())
        .modelContainer(for: Snippet.self, inMemory: true)
}
