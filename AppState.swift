//
//  AppState.swift
//  SnipKit
//

import SwiftUI

@Observable
@MainActor
final class AppState {
    var newSnippetTrigger: Int = 0
    var focusSearchTrigger: Int = 0
}
