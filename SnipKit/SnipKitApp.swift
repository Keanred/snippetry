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

    init() {
        KeyboardShortcuts.onKeyDown(for: .togglePicker) {
            Self.togglePicker()
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(container)
            .commands {
                CommandMenu("Snippets") {
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
        let button: NSStatusBarButton? = NSApp.windows.lazy.compactMap { window in
            (window.contentView as? NSStatusBarButton)
                ?? window.contentView?.subviews.lazy.compactMap({ $0 as? NSStatusBarButton }).first
        }.first
        button?.performClick(nil)
    }
}

