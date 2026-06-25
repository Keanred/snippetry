//
//  HighlightedCodeView.swift
//  Snippetry
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

    private var themeName: String {
        colorScheme == .dark ? "xcode-dark" : "xcode"
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
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
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false

        textView.string = code

        context.coordinator.parent = self
        context.coordinator.textView = textView
        context.coordinator.currentLanguage = language
        context.coordinator.currentTheme = themeName
        context.coordinator.applyHighlight()
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView,
              let storage = textView.textStorage
        else { return }

        let contentChanged = textView.string != code
        let languageChanged = context.coordinator.currentLanguage != language
        let themeChanged = context.coordinator.currentTheme != themeName

        if contentChanged {
            let selection = textView.selectedRanges
            storage.replaceCharacters(
                in: NSRange(location: 0, length: storage.length),
                with: code
            )
            textView.selectedRanges = selection
        }

        if contentChanged || languageChanged || themeChanged {
            context.coordinator.currentLanguage = language
            context.coordinator.currentTheme = themeName
            context.coordinator.applyHighlight()
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightedCodeEditor?
        weak var textView: NSTextView?
        var currentLanguage: String?
        var currentTheme: String?
        private var pending: DispatchWorkItem?

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent?.code = textView.string
            schedule()
        }

        private func schedule() {
            pending?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.applyHighlight()
            }
            pending = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + .milliseconds(80),
                execute: work
            )
        }

        func applyHighlight() {
            pending?.cancel()
            pending = nil
            guard let textView = textView,
                  let storage = textView.textStorage,
                  let parent = parent
            else { return }

            let currentText = textView.string
            let ns = HighlightrPool.shared.highlight(
                code: currentText,
                language: parent.language,
                theme: currentTheme ?? "xcode"
            )
            guard ns.string == currentText else { return }

            let baseFont = NSFont.monospacedSystemFont(
                ofSize: NSFont.systemFontSize, weight: .regular
            )
            let fullRange = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            storage.setAttributes([.font: baseFont], range: fullRange)
            ns.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: ns.length)) { value, range, _ in
                guard let color = value as? NSColor,
                      range.location + range.length <= storage.length
                else { return }
                storage.addAttribute(.foregroundColor, value: color, range: range)
            }
            storage.endEditing()
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
            NSLog("[Snippetry] Highlightr failed to initialize (JS/CSS resources missing).")
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
