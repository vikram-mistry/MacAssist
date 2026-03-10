// AppBundleParser.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation
import OSLog

/// Parses .app bundles to extract metadata from Info.plist.
struct AppBundleParser: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "AppBundleParser")

    /// Parses an application bundle and returns an ApplicationItem.
    static func parse(at path: String) -> ApplicationItem? {
        let url = URL(fileURLWithPath: path)
        let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")

        guard FileManager.default.fileExists(atPath: infoPlistURL.path) else {
            logger.warning("No Info.plist found at \(infoPlistURL.path)")
            return nil
        }

        guard let data = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            logger.error("Failed to parse Info.plist at \(infoPlistURL.path)")
            return nil
        }

        let name = plist["CFBundleName"] as? String
            ?? plist["CFBundleDisplayName"] as? String
            ?? url.deletingPathExtension().lastPathComponent

        let bundleID = plist["CFBundleIdentifier"] as? String ?? "unknown"
        let version = plist["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = plist["CFBundleVersion"] as? String ?? ""

        // Calculate app bundle size
        let size = calculateBundleSize(at: path)

        // Get last opened date from Launch Services
        let lastOpened = getLastOpenedDate(for: url)

        // Get icon path
        let iconName = plist["CFBundleIconFile"] as? String ?? plist["CFBundleIconName"] as? String
        let iconPath = iconName.map { iconFileName -> String in
            let resourcesPath = url.appendingPathComponent("Contents/Resources")
            let icnFile = resourcesPath.appendingPathComponent(iconFileName)
            if FileManager.default.fileExists(atPath: icnFile.path) {
                return icnFile.path
            }
            let icnsFile = resourcesPath.appendingPathComponent("\(iconFileName).icns")
            return icnsFile.path
        }

        return ApplicationItem(
            name: name,
            bundleIdentifier: bundleID,
            version: version,
            buildNumber: buildNumber,
            installPath: path,
            size: size,
            lastOpened: lastOpened,
            iconPath: iconPath
        )
    }

    /// Calculate the total size of an app bundle.
    private static func calculateBundleSize(at path: String) -> UInt64 {
        let fileManager = FileManager.default
        var totalSize: UInt64 = 0

        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: [],
            errorHandler: nil
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]) {
                totalSize += UInt64(values.totalFileAllocatedSize ?? 0)
            }
        }

        return totalSize
    }

    /// Attempts to get the last opened date for an application.
    private static func getLastOpenedDate(for appURL: URL) -> Date? {
        let keys: Set<URLResourceKey> = [.contentAccessDateKey]
        guard let values = try? appURL.resourceValues(forKeys: keys) else { return nil }
        return values.contentAccessDate
    }
}
