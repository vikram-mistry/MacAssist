// AppDiscoveryService.swift
// MacAssist

import Foundation
import OSLog

/// Discovers installed applications in standard locations.
struct AppDiscoveryService: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "AppDiscoveryService")

    static let searchPaths: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return ["/Applications", "\(home)/Applications"]
    }()

    func discoverApplications() -> [ApplicationItem] {
        var apps: [ApplicationItem] = []
        for searchPath in Self.searchPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: searchPath) else { continue }
            for item in contents where item.hasSuffix(".app") {
                if let app = AppBundleParser.parse(at: "\(searchPath)/\(item)") { apps.append(app) }
            }
        }
        // Scan nested directories in /Applications.
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: "/Applications") {
            for item in contents {
                let fullPath = "/Applications/\(item)"
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir),
                   isDir.boolValue, !item.hasSuffix(".app") {
                    if let nested = try? FileManager.default.contentsOfDirectory(atPath: fullPath) {
                        for nestedItem in nested where nestedItem.hasSuffix(".app") {
                            if let app = AppBundleParser.parse(at: "\(fullPath)/\(nestedItem)") { apps.append(app) }
                        }
                    }
                }
            }
        }
        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
