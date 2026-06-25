//
//  SnippetryApp.swift
//  Snippetry
//
//  Created by Anssi Keinänen on 10.6.2026.
//

import SwiftUI
import SwiftData
import AppKit
import KeyboardShortcuts

@main
struct SnippetryApp: App {
    let container: ModelContainer = {
        let config = ModelConfiguration(cloudKitDatabase: .private("iCloud.keanred.Snippetry"))
        do {
            return try ModelContainer(
                for: Snippet.self, Tag.self, Folder.self,
                configurations: config
            )
        } catch {
            NSLog("[Snippetry] ModelContainer failed: \(error)")
            fatalError("ModelContainer failed: \(error)")
        }
    }()

    @State private var appState = AppState()

    init() {
        KeyboardShortcuts.onKeyDown(for: .togglePicker) {
            Self.togglePicker()
        }
        Folder.seedDefaultsIfNeeded(in: container.mainContext)
        Tag.seedDefaultsIfNeeded(in: container.mainContext)
    }

    var body: some Scene {

        WindowGroup { ContentView().environment(appState) }
            .modelContainer(container)
            .commands {
                CommandGroup(replacing: .newItem) {
                    Button("New Snippet") {
                        appState.send(.new)
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                }
                CommandMenu("Snippets") {
                    Button("Focus Search") {
                        appState.send(.focusSearch)
                    }
                    .keyboardShortcut("f", modifiers: [.command])
                    Divider()
                    Button("Copy Snippet") {
                        appState.send(.copy)
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    Button("Duplicate Snippet") {
                        appState.send(.duplicate)
                    }
                    .keyboardShortcut("d", modifiers: [.command])
                    Button("Delete Snippet") {
                        appState.send(.delete)
                    }
                    .keyboardShortcut(.delete, modifiers: [.command])
                    Divider()
                    Button("Toggle Snippet Picker") {
                        Self.togglePicker()
                    }
                    .globalKeyboardShortcut(.togglePicker)
                }
            }

        MenuBarExtra("Snippetry", image: "MenuBarIcon") {
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
