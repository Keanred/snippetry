//
//  SnipKitApp.swift
//  SnipKit
//
//  Created by Anssi Keinänen on 10.6.2026.
//

import SwiftUI
import SwiftData
import AppKit
import KeyboardShortcuts

@main
struct SnipShelfApp: App {
    let container: ModelContainer = {
        try! ModelContainer(for: Snippet.self, Tag.self, Folder.self)
    }()

    @State private var appState = AppState()

    init() {
        KeyboardShortcuts.onKeyDown(for: .togglePicker) {
            Self.togglePicker()
        }
    }

    var body: some Scene {

        WindowGroup { ContentView().environment(appState) }
            .modelContainer(container)
            .commands {
                CommandGroup(replacing: .newItem) {
                    Button("New Snippet") {
                        appState.newSnippetTrigger &+= 1
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                }
                CommandMenu("Snippets") {
                    Button("Focus Search") {
                        appState.focusSearchTrigger &+= 1
                    }
                    .keyboardShortcut("f", modifiers: [.command])
                    Divider()
                    Button("Toggle Snippet Picker") {
                        Self.togglePicker()
                    }
                    .globalKeyboardShortcut(.togglePicker)
                }
            }

        MenuBarExtra("SnipKit", systemImage: "chevron.left.forwardslash.chevron.right") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
        .modelContainer(container)

        Settings {
            SettingsView()
        }
    }

    private static func togglePicker() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            guard let content = window.contentView,
                  let button = findStatusButton(in: content)
            else { continue }
            button.performClick(nil)
            return
        }
    }

    private static func findStatusButton(in view: NSView) -> NSStatusBarButton? {
        if let button = view as? NSStatusBarButton {
            return button
        }
        for subview in view.subviews {
            if let found = findStatusButton(in: subview) {
                return found
            }
        }
        return nil
    }
}
