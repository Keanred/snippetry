//
//  TagEditorSheet.swift
//  SnipKit
//

import SwiftUI
import SwiftData

struct TagEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let editingTag: Tag?
    @State private var name: String = ""
    @State private var color: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(editingTag == nil ? "New Tag" : "Edit Tag")
                .font(.headline)
            TextField("Tag name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(commit)
            ColorPicker("Color", selection: $color, supportsOpacity: false)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(editingTag == nil ? "Add" : "Save", action: commit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 320)
        .onAppear {
            if let editingTag {
                name = editingTag.name
                color = editingTag.color ?? .blue
            } else {
                name = ""
                color = .blue
            }
        }
    }

    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let editingTag {
            editingTag.name = trimmed
            editingTag.colorHex = color.hexString
        } else {
            modelContext.insert(Tag(name: trimmed, colorHex: color.hexString))
        }
        dismiss()
    }
}
