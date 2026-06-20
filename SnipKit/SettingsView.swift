//
//  SettingsView.swift
//  SnipKit
//

import SwiftUI
import KeyboardShortcuts
import ServiceManagement
import AppKit

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gear") }
            ShortcutsSettings()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            AboutSettings()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500, height: 380)
    }
}

private struct GeneralSettings: View {
    @AppStorage("defaultLanguage") private var defaultLanguage: String = "plaintext"
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var loginStatus: SMAppService.Status = SMAppService.mainApp.status
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Snippets") {
                Picker("Default language", selection: $defaultLanguage) {
                    ForEach(Languages.popular, id: \.self) { lang in
                        Text(lang).tag(lang)
                    }
                }
            }

            Section {
                Toggle("Launch SnipKit at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(newValue)
                    }

                if loginStatus == .requiresApproval {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Approval required in System Settings.")
                        Spacer()
                        Button("Open Login Items…") {
                            SMAppService.openSystemSettingsLoginItems()
                        }
                        .controlSize(.small)
                    }
                    .font(.callout)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "xmark.octagon.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } header: {
                Text("Startup")
            } footer: {
                Text("SnipKit will launch silently in the menu bar after login.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear { refreshStatus() }
        .task {
            for await _ in NotificationCenter.default.notifications(
                named: NSApplication.didBecomeActiveNotification
            ) {
                refreshStatus()
            }
        }
    }

    private func refreshStatus() {
        loginStatus = SMAppService.mainApp.status
        launchAtLogin = loginStatus == .enabled
    }

    private func updateLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            launchAtLogin = !enable
            errorMessage = error.localizedDescription
        }
        loginStatus = SMAppService.mainApp.status
    }
}

private struct ShortcutsSettings: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Toggle snippet picker", name: .togglePicker)
            } header: {
                Text("Global")
            } footer: {
                Text("Works from any app, even when SnipKit isn't focused.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("In-app") {
                ShortcutRow(label: "New snippet", keys: "⌘N")
                ShortcutRow(label: "Focus search", keys: "⌘F")
                ShortcutRow(label: "Copy snippet", keys: "⇧⌘C")
                ShortcutRow(label: "Open settings", keys: "⌘,")
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutRow: View {
    let label: String
    let keys: String

    var body: some View {
        LabeledContent(label) {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

private struct AboutSettings: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .resizable()
                .interpolation(.high)
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            Text("SnipKit")
                .font(.title2.weight(.semibold))

            Text("Version \(version) (\(build))")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("Your code snippets, one keystroke away.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

#Preview {
    SettingsView()
}
