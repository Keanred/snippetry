//
//  HighlightedCodeView.swift
//  SnipKit
//

import SwiftUI
import AppKit
import Highlightr

struct HighlightedCodeView: View {
    let code: String
    let language: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(attributedCode)
                .textSelection(.enabled)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var attributedCode: AttributedString {
        let themeName = colorScheme == .dark ? "xcode-dark" : "xcode"
        let ns = HighlightrPool.shared.highlight(
            code: code,
            language: language,
            theme: themeName
        )
        return Self.attributedString(from: ns)
    }

    private static func attributedString(from ns: NSAttributedString) -> AttributedString {
        let plain = ns.string
        var result = AttributedString(plain)
        let full = NSRange(location: 0, length: ns.length)
        ns.enumerateAttribute(.foregroundColor, in: full) { value, nsRange, _ in
            guard let nsColor = value as? NSColor,
                  let stringRange = Range(nsRange, in: plain),
                  let lower = AttributedString.Index(stringRange.lowerBound, within: result),
                  let upper = AttributedString.Index(stringRange.upperBound, within: result)
            else { return }
            result[lower..<upper].foregroundColor = Color(nsColor: nsColor)
        }
        return result
    }
}

struct HighlightedCodeEditor: NSViewRepresentable {
    @Binding var code: String
    let language: String

    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = CodeAttributedString()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let container = NSTextContainer(
            containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        )
        container.widthTracksTextView = true
        container.heightTracksTextView = false
        layoutManager.addTextContainer(container)

        let textView = NSTextView(frame: .zero, textContainer: container)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.font = NSFont.monospacedSystemFont(
            ofSize: NSFont.systemFontSize, weight: .regular
        )
        textView.delegate = context.coordinator
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        context.coordinator.parent = self
        context.coordinator.textStorage = textStorage

        if textView.string != code {
            textView.string = code
        }
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView,
              let storage = context.coordinator.textStorage
        else { return }

        let themeName = colorScheme == .dark ? "xcode-dark" : "xcode"
        if context.coordinator.currentTheme != themeName {
            _ = storage.highlightr.setTheme(to: themeName)
            context.coordinator.currentTheme = themeName
        }

        let resolved = HighlightrPool.resolve(language, against: storage.highlightr.supportedLanguages())
        let languageChanged = storage.language != resolved
        let contentChanged = textView.string != code

        if contentChanged {
            let selection = textView.selectedRanges
            let baseFont = NSFont.monospacedSystemFont(
                ofSize: NSFont.systemFontSize, weight: .regular
            )
            storage.beginEditing()
            storage.replaceCharacters(
                in: NSRange(location: 0, length: storage.length),
                with: code
            )
            storage.setAttributes(
                [.font: baseFont],
                range: NSRange(location: 0, length: storage.length)
            )
            storage.endEditing()
            textView.selectedRanges = selection
        }

        if languageChanged {
            storage.language = resolved
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightedCodeEditor?
        var textStorage: CodeAttributedString?
        var currentTheme: String?

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent?.code = textView.string
        }
    }
}

@MainActor
final class HighlightrPool {
    static let shared = HighlightrPool()

    private let highlightr: Highlightr?
    private var currentTheme: String?
    private let fallbackFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    private init() {
        self.highlightr = Highlightr()
        if highlightr == nil {
            NSLog("[SnipKit] Highlightr failed to initialize (JS/CSS resources missing).")
        }
    }

    func highlight(code: String, language: String, theme: String) -> NSAttributedString {
        guard let highlightr else {
            return NSAttributedString(
                string: code,
                attributes: [.font: fallbackFont]
            )
        }
        if currentTheme != theme {
            _ = highlightr.setTheme(to: theme)
            currentTheme = theme
        }
        let resolved = Self.resolve(language, against: highlightr.supportedLanguages())
        let result = highlightr.highlight(code, as: resolved, fastRender: true)
        return result ?? NSAttributedString(
            string: code,
            attributes: [.font: fallbackFont]
        )
    }

    static func resolve(_ language: String, against supported: [String]) -> String? {
        let lower = language.trimmingCharacters(in: .whitespaces).lowercased()
        guard !lower.isEmpty, lower != "plaintext" else { return nil }
        if let mapped = aliases[lower], supported.contains(mapped) { return mapped }
        if supported.contains(lower) { return lower }
        return nil
    }

    private static let aliases: [String: String] = [
        "c++": "cpp",
        "cplusplus": "cpp",
        "c#": "cs",
        "csharp": "cs",
        "objective-c": "objectivec",
        "objc": "objectivec",
        "obj-c": "objectivec",
        "sh": "bash",
        "shell": "bash",
        "zsh": "bash",
        "html": "xml",
        "htm": "xml",
        "js": "javascript",
        "ts": "typescript",
        "py": "python",
        "rb": "ruby",
        "yml": "yaml",
        "md": "markdown"
    ]
}
