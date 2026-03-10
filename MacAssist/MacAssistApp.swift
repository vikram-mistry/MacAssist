// MacAssistApp.swift
// MacAssist

import SwiftUI

@main
struct MacAssistApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1100, height: 700)
    }
}
