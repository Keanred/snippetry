//
//  AppState.swift
//  Snippetry
//

import SwiftUI

enum Command {
    case new,
    focusSearch,
    copy,
    duplicate,
    delete
}

@Observable
@MainActor
final class AppState {
    private(set) var lastCommand: Command?
    private(set) var commandID: Int = 0

    func send(_ command: Command) {
        lastCommand = command
        commandID &+= 1
    }
}
