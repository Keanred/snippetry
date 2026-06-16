//
//  SnippetDetailView.swift
//  SnipKit
//

import SwiftUI
import SwiftData

struct SnippetDetailView: View {
    @Bindable var snippet: Snippet
    @Query(sort: \Folder.createdAt) private var folders: [Folder]
    @Query(sort: \Tag.createdAt) private var tags: [Tag]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Untitled Snippet", text: $snippet.title)
                .textFieldStyle(.plain)
                .font(.largeTitle.weight(.semibold))
                .lineLimit(1)

            Divider()

            codeEditor
            folderRow
            languageRow
            tagsRow
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var codeEditor: some View {
        HighlightedCodeEditor(code: $snippet.code, language: snippet.language)
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: .infinity, minHeight: 300)
    }

    private var folderRow: some View {
        HStack(spacing: 6) {
            Label("Folder", systemImage: "folder")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.secondary)
            Picker("Folder", selection: $snippet.folder) {
                Text("None").tag(nil as Folder?)
                ForEach(folders.filter { $0.name != "All snippets" }) { folder in
                    Text(folder.name).tag(folder as Folder?)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 200)
        }
    }

    private var languageRow: some View {
        HStack(spacing: 6) {
            Label("Language", systemImage: "chevron.left.forwardslash.chevron.right")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.secondary)
            TextField("plaintext", text: $snippet.language)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)
            Menu {
                ForEach(Languages.popular, id: \.self) { lang in
                    Button {
                        snippet.language = lang
                    } label: {
                        if snippet.language == lang {
                            Label(lang, systemImage: "checkmark")
                        } else {
                            Text(lang)
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
            }
            .fixedSize()
        }
    }

    private var tagsRow: some View {
        HStack(spacing: 6) {
            Label("Tags", systemImage: "tag")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(snippet.tags) { tag in
                        tagChip(tag)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(height: 24)
            Menu {
                ForEach(tags.filter { !Tag.defaultNames.contains($0.name) }) { tag in
                    Button {
                        if let i = snippet.tags.firstIndex(of: tag) {
                            snippet.tags.remove(at: i)
                        } else {
                            snippet.tags.append(tag)
                        }
                    } label: {
                        if snippet.tags.contains(tag) {
                            Label(tag.name, systemImage: "checkmark")
                        } else {
                            Text(tag.name)
                        }
                    }
                }
            } label: {
                Image(systemName: "plus")
            }
            .fixedSize()
        }
    }

    private func tagChip(_ tag: Tag) -> some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.caption)
            Button {
                if let i = snippet.tags.firstIndex(of: tag) {
                    snippet.tags.remove(at: i)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill((tag.color ?? .accentColor).opacity(0.2)))
        .overlay(Capsule().stroke((tag.color ?? .accentColor).opacity(0.5), lineWidth: 0.5))
    }
}
