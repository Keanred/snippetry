//
//  Models.swift
//  Snippetry
//
//  Created by Anssi Keinänen on 10.6.2026.
//

import Foundation
import SwiftData
import SwiftUI

@Model final class Snippet {
    var title: String = ""
    var code: String = ""
    var language: String = "plaintext"
    var createdAt: Date = Date.now
    var folder: Folder?
    @Relationship(inverse: \Tag.snippets) var tags: [Tag]?

    init(title: String, code: String, language: String = "plaintext") {
        self.title = title
        self.code = code
        self.language = language
        self.createdAt = .now
    }
}

@Model final class Tag {
    var name: String = ""
    var createdAt: Date = Date.now
    var colorHex: String?
    var snippets: [Snippet]?

    init(name: String, colorHex: String? = nil) {
        self.name = name
        self.createdAt = .now
        self.colorHex = colorHex
    }
}

extension Tag {
    static let defaultNames = ["All tags"]
    private static let didSeedDefaultsKey = "Tag.didSeedDefaults"

    var color: Color? {
        colorHex.flatMap { Color(hex: $0) }
    }

    @MainActor
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: didSeedDefaultsKey) else { return }
        let existing = (try? context.fetch(FetchDescriptor<Tag>())) ?? []
        let existingNames = Set(existing.map(\.name))
        for name in defaultNames where !existingNames.contains(name) {
            context.insert(Tag(name: name))
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: didSeedDefaultsKey)
    }
}

@Model final class Folder {
    var name: String = ""
    var createdAt: Date = Date.now
    @Relationship(deleteRule: .nullify, inverse: \Snippet.folder)
    var snippets: [Snippet]?

    init(name: String) {
        self.name = name
        self.createdAt = .now
    }
}

extension Folder {
    static let defaultNames = ["All snippets", "Favorites", "Trash"]
    private static let didSeedDefaultsKey = "Folder.didSeedDefaults"

    @MainActor
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: didSeedDefaultsKey) else { return }
        let existing = (try? context.fetch(FetchDescriptor<Folder>())) ?? []
        let existingNames = Set(existing.map(\.name))
        for name in defaultNames where !existingNames.contains(name) {
            context.insert(Folder(name: name))
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: didSeedDefaultsKey)
    }
}
