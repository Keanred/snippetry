//
//  SnipKitApp.swift
//  SnipKit
//
//  Created by Anssi Keinänen on 10.6.2026.
//

import SwiftUI
import SwiftData

@main
struct SnipKitApp: App {
    @MainActor
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Snippet.self, Tag.self, Folder.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            Folder.seedDefaultsIfNeeded(in: container.mainContext)
            Tag.seedDefaultsIfNeeded(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
