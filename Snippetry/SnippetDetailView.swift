//
//  SnippetDetailView.swift
//  Snippetry
//

import SwiftUI
import SwiftData
import AppKit

struct SnippetDetailView: View {
    @Bindable var snippet: Snippet
    @Query(sort: \Folder.createdAt) private var folders: [Folder]
    @Query(sort: \Tag.createdAt) private var tags: [Tag]
    @State private var didCopy: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            codeEditor
            HStack(spacing: 12) {
                inlineCopyButton
                Spacer()
            }
            HStack(spacing: 16) {
                folderRow
                languageRow
            }
            tagsRow
            metadataBar
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField("Untitled Snippet", text: $snippet.title)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(minWidth: 200, idealWidth: 320, maxWidth: 480)
            }
            ToolbarItem(placement: .primaryAction) {
                copyButton
            }
        }
    }

    private var copyButton: some View {
        Button {
            copyCode()
        } label: {
            Label(
                didCopy ? "Copied" : "Copy",
                systemImage: didCopy ? "checkmark.circle.fill" : "doc.on.doc"
            )
        }
        .help("Copy snippet to clipboard")
    }

    private var inlineCopyButton: some View {
        Button {
            copyCode()
        } label: {
            Label(
                didCopy ? "Copied to clipboard" : "Copy to Clipboard",
                systemImage: didCopy ? "checkmark.circle.fill" : "doc.on.doc"
            )
            .labelStyle(.titleAndIcon)
            .font(.callout.weight(.medium))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .tint(didCopy ? .green : .accentColor)
        .help("Copy snippet to clipboard (⇧⌘C)")
    }

    private func copyCode() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(snippet.code, forType: .string)
        withAnimation(.easeOut(duration: 0.15)) {
            didCopy = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.easeIn(duration: 0.15)) {
                didCopy = false
            }
        }
    }

    private var codeEditor: some View {
        HighlightedCodeEditor(code: $snippet.code, language: snippet.language)
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    .allowsHitTesting(false)
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
            Picker("Language", selection: $snippet.language) {
                ForEach(Languages.popular, id: \.self) { lang in
                    Text(lang).tag(lang)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 200)
        }
    }

    private var metadataBar: some View {
        HStack(spacing: 14) {
            Label {
                Text("Created \(snippet.createdAt.formatted(date: .abbreviated, time: .omitted))")
            } icon: {
                Image(systemName: "calendar")
            }
            Spacer(minLength: 0)
            Text("\(snippet.code.count) chars")
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: snippet.code.count)
            Text("\(lineCount) lines")
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: lineCount)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 2)
    }

    private var lineCount: Int {
        snippet.code.isEmpty ? 0 : snippet.code.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count
    }

    private var tagsRow: some View {
        HStack(spacing: 6) {
            Label("Tags", systemImage: "tag")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(snippet.tags ?? []) { tag in
                        tagChip(tag)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.6).combined(with: .opacity),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    }
                }
                .padding(.vertical, 2)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: snippet.tags)
            }
            .frame(height: 24)
            Menu {
                ForEach(tags.filter { !Tag.defaultNames.contains($0.name) }) { tag in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            var tags = snippet.tags ?? []
                            if let i = tags.firstIndex(of: tag) {
                                tags.remove(at: i)
                            } else {
                                tags.append(tag)
                            }
                            snippet.tags = tags
                        }
                    } label: {
                        if (snippet.tags ?? []).contains(tag) {
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
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    var tags = snippet.tags ?? []
                    if let i = tags.firstIndex(of: tag) {
                        tags.remove(at: i)
                        snippet.tags = tags
                    }
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
