//
//  MenuBarView.swift
//  SnipKit
//
//  Created by Anssi Keinänen on 15.6.2026.
//

import SwiftUI
import SwiftData
#if canImport(AppKit)
import AppKit
#endif
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePicker = Self(
        "togglePicker",
        initial: .init(.v, modifiers: [.control, .option, .command])
    )
}

struct MenuBarView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var snippets: [Snippet] = []
    @State private var searchText: String = ""
    @State private var copiedSnippetID: PersistentIdentifier?
    @State private var selectedIndex: Int = 0
    @FocusState private var searchFocused: Bool

    private var visibleSnippets: [Snippet] {
        Array(filteredSnippets.prefix(20))
    }

    private var filteredSnippets: [Snippet] {
        guard !searchText.isEmpty else { return snippets }
        return snippets.filter { snippet in
            snippet.title.localizedStandardContains(searchText)
                || snippet.code.localizedStandardContains(searchText)
                || snippet.language.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search snippets", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)
                .onChange(of: searchText) { _, _ in
                    selectedIndex = 0
                }
                .onKeyPress(.upArrow) {
                    moveSelection(-1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    moveSelection(1)
                    return .handled
                }
                .onKeyPress(.return) {
                    copySelected()
                    return .handled
                }
                .onKeyPress(.escape) {
                    #if canImport(AppKit)
                    NSApp.deactivate()
                    #endif
                    return .handled
                }
                .padding(8)

            Divider()

            if visibleSnippets.isEmpty {
                Text(snippets.isEmpty ? "No snippets" : "No matches")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(visibleSnippets.enumerated()), id: \.element.id) { index, snippet in
                                SnippetRow(snippet: snippet,
                                           isCopied: snippet.persistentModelID == copiedSnippetID,
                                           isSelected: index == selectedIndex) {
                                    selectedIndex = index
                                    copy(snippet)
                                }
                                .id(index)
                                Divider()
                            }
                        }
                    }
                    .frame(minHeight: 320)
                    .onChange(of: selectedIndex) { _, new in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(new, anchor: .center)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 10) {
                hintLabel("↑↓", "Navigate")
                hintLabel("↵", "Copy")
                hintLabel("⎋", "Close")
                Spacer(minLength: 0)
                Button {
                    #if canImport(AppKit)
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    #endif
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
                .help("Settings…")
                Button("Quit") {
                    #if canImport(AppKit)
                    NSApp.terminate(nil)
                    #endif
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .frame(width: 320)
        .onAppear {
            copiedSnippetID = nil
            selectedIndex = 0
            reload()
            searchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            reload()
        }
    }

    private func hintLabel(_ key: String, _ label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.caption2.monospaced())
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.secondary.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 3))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func moveSelection(_ delta: Int) {
        let count = visibleSnippets.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + delta + count) % count
    }

    private func copySelected() {
        let list = visibleSnippets
        guard list.indices.contains(selectedIndex) else { return }
        copy(list[selectedIndex])
    }

    private func reload() {
        try? modelContext.save()
        let descriptor = FetchDescriptor<Snippet>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        snippets = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func copy(_ snippet: Snippet) {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snippet.code, forType: .string)
        #endif
        withAnimation(.easeOut(duration: 0.15)) {
            copiedSnippetID = snippet.persistentModelID
        }
        Task {
            try? await Task.sleep(for: .milliseconds(550))
            #if canImport(AppKit)
            NSApp.deactivate()
            #endif
        }
    }
}

private struct SnippetRow: View {
    let snippet: Snippet
    let isCopied: Bool
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.body)
                    .lineLimit(1)
                Text(snippet.language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if isCopied {
                Label {
                    Text("Copied")
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolEffect(.bounce, value: isCopied)
                }
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture(perform: action)
    }

    private var rowBackground: Color {
        if isCopied { return Color.green.opacity(0.18) }
        if isSelected { return Color.accentColor.opacity(0.22) }
        if isHovering { return Color.accentColor.opacity(0.12) }
        return .clear
    }
}

#Preview {
    MenuBarView()
        .modelContainer(for: Snippet.self, inMemory: true)
}
