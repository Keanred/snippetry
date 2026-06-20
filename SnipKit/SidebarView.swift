//
//  SidebarView.swift
//  SnipKit
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.createdAt) private var folders: [Folder]
    @Query(sort: \Tag.createdAt) private var tags: [Tag]
    @Binding var folderSelection: Folder?
    @Binding var tagSelection: Tag?
    let onAddTag: () -> Void
    let onEditTag: (Tag) -> Void
    let onAddSnippet: () -> Void

    var body: some View {
        Group {
            List(selection: $folderSelection) {
                Section("LIBRARY") {
                    ForEach(folders) { folder in
                        Label(folder.name, systemImage: folderIcon(folder.name))
                            .tag(folder)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)

            List(selection: $tagSelection) {
                Section {
                    ForEach(tags) { tag in
                        Label {
                            Text(tag.name)
                        } icon: {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(tag.color ?? .secondary)
                        }
                        .tag(tag)
                        .contextMenu {
                            if !Tag.defaultNames.contains(tag.name) {
                                Button("Edit") { onEditTag(tag) }
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(tag)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("TAGS")
                        Spacer()
                        Button(action: onAddTag) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: onAddSnippet) {
                        Label("Add snippet", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func folderIcon(_ name: String) -> String {
        switch name {
        case "All snippets": return "tray.full"
        case "Favorites": return "star"
        case "Trash": return "trash"
        default: return "folder"
        }
    }
}
