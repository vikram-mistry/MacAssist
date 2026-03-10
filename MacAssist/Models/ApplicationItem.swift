// ApplicationItem.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation

/// Represents an installed macOS application with metadata.
struct ApplicationItem: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let version: String
    let buildNumber: String
    let installPath: String
    let size: UInt64
    let lastOpened: Date?
    let iconPath: String?
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        version: String = "Unknown",
        buildNumber: String = "",
        installPath: String,
        size: UInt64,
        lastOpened: Date? = nil,
        iconPath: String? = nil,
        isSelected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.buildNumber = buildNumber
        self.installPath = installPath
        self.size = size
        self.lastOpened = lastOpened
        self.iconPath = iconPath
        self.isSelected = isSelected
    }

    /// All known associated file locations for deep uninstall.
    var associatedPaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/Library/Application Support/\(name)",
            "\(home)/Library/Application Support/\(bundleIdentifier)",
            "\(home)/Library/Caches/\(bundleIdentifier)",
            "\(home)/Library/Logs/\(name)",
            "\(home)/Library/Preferences/\(bundleIdentifier).plist",
            "\(home)/Library/Containers/\(bundleIdentifier)",
            "\(home)/Library/Saved Application State/\(bundleIdentifier).savedState",
            "\(home)/Library/WebKit/\(bundleIdentifier)",
            "\(home)/Library/HTTPStorages/\(bundleIdentifier)",
            "\(home)/Library/Cookies/\(bundleIdentifier).binarycookies",
            "\(home)/Library/Group Containers/\(bundleIdentifier)",
            "\(home)/Library/Application Scripts/\(bundleIdentifier)"
        ]
    }
}
