//
//  SettingsView.swift
//  SnipKit
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle picker:", name: .togglePicker)
        }
        .padding(20)
        .frame(width: 360)
    }
}

#Preview {
    SettingsView()
}
