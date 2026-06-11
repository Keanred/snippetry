//
//  Models.swift
//  SnipKit
//
//  Created by Anssi Keinänen on 10.6.2026.
//

import Foundation
import SwiftData

@Model final class Snippet {
    var title: String = ""
    var code: String = ""
    var language: String = "plaintext"
    var createdAt: Date = Date.now
    var folder: Folder?
    @Relationship(inverse: \Tag.snippets) var tags: [Tag] = []

    init(title: String, code: String, language: String = "plaintext") {
        self.title = title
        self.code = code
        self.language = language
        self.createdAt = .now
    }
}

@Model final class Tag {
    var name: String = ""
    var snippets: [Snippet] = []

    init(name: String) { self.name = name }
}

@Model final class Folder {
    var name: String = ""
    @Relationship(deleteRule: .nullify, inverse: \Snippet.folder)
    var snippets: [Snippet] = []

    init(name: String) { self.name = name }
}
