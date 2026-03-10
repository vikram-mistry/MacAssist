// JunkItem.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation

/// Represents an individual junk file or directory detected during scanning.
struct JunkItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let path: String
    let name: String
    let size: UInt64
    let category: JunkCategory
    let severity: JunkSeverity
    var isSelected: Bool
    let lastModified: Date?
    let isDirectory: Bool
    let appName: String

    init(
        id: UUID = UUID(),
        path: String,
        name: String,
        size: UInt64,
        category: JunkCategory,
        severity: JunkSeverity = .safe,
        isSelected: Bool = true,
        lastModified: Date? = nil,
        isDirectory: Bool = false,
        appName: String? = nil
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.size = size
        self.category = category
        self.severity = severity
        self.isSelected = isSelected
        self.lastModified = lastModified
        self.isDirectory = isDirectory
        
        let extractedApp = JunkItem.extractAppName(from: name, path: path)
        self.appName = appName ?? extractedApp
    }
    
    var deletionReason: String {
        return category.deletionReason(forAppName: appName)
    }

    private static func extractAppName(from rawName: String, path: String) -> String {
        // If it looks like a bundle ID: "com.apple.Safari" -> "Safari"
        if rawName.contains(".") && !rawName.hasSuffix(".plist") && !rawName.hasSuffix(".log") {
            let components = rawName.components(separatedBy: ".")
            if components.count > 2, let last = components.last {
                return last.replacingOccurrences(of: " (deleted)", with: "")
            }
        }
        
        // If it's a file, maybe the parent directory is the app name
        let pathParts = path.components(separatedBy: "/")
        if pathParts.count >= 2 {
            let parent = pathParts[pathParts.count - 2]
            if parent != "Caches" && parent != "Logs" && parent != "Preferences" && parent != "Application Support" {
                if parent.contains(".") {
                    return parent.components(separatedBy: ".").last ?? parent
                }
                return parent
            }
        }
        
        return rawName.replacingOccurrences(of: ".plist", with: "").replacingOccurrences(of: ".log", with: "")
    }
}

/// Categories for junk classification.
enum JunkCategory: String, Codable, CaseIterable, Sendable {
    case caches = "Caches"
    case logs = "Logs"
    case temporary = "Temporary"
    case preferences = "Preferences"
    case appSupport = "App Support"
    case developer = "Developer"
    case trash = "Trash"
    case applicationLeftover = "App Leftover"

    var icon: String {
        switch self {
        case .caches: return "archivebox"
        case .logs: return "doc.text"
        case .temporary: return "clock.arrow.circlepath"
        case .preferences: return "gearshape"
        case .appSupport: return "folder.badge.questionmark"
        case .developer: return "hammer"
        case .trash: return "trash"
        case .applicationLeftover: return "app.badge.checkmark"
        }
    }
    
    func deletionReason(forAppName appName: String) -> String {
        let cleanName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = cleanName.isEmpty || cleanName.lowercased() == "caches" || cleanName.lowercased() == "logs" ? "this app" : cleanName
        
        switch self {
        case .caches:
            return "Caches are temporary files created to speed up load times for \(target). Deleting them is completely safe; the app will automatically recreate them if needed on next launch."
        case .logs:
            return "Logs contain plain text records of background activities and errors for \(target). They are mainly for developer debugging. Deleting them is 100% safe and will not affect the app's performance."
        case .temporary:
            return "Temporary and ephemeral system files that macOS or apps forgot to clean up. Safe to delete to reclaim immediate storage space."
        case .trash:
            return "Files and folders you have already moved to the Trash. Permanently deleting these clears up disk space instantly."
        case .appSupport:
            return "Isolated background support files for \(target) that are designated as safe to clear. Doing so frees up storage without corrupting the main app."
        case .preferences:
            return "Settings and configuration files. Deleting them resets the preferences for \(target) back to their defaults. Only delete if you are okay with reconfiguring the app."
        case .developer:
            return "Leftover build artifacts and derived data created by Xcode. Highly recommended to delete occasionally to free up massive amounts of storage."
        case .applicationLeftover:
            return "Leftover files from an application that has already been uninstalled. Completely safe and highly recommended to permanently remove."
        }
    }
}

/// Severity level indicating safety of deletion.
enum JunkSeverity: String, Codable, Sendable {
    case safe
    case caution
    case warning
}
