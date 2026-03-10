// CacheScanner.swift
// MacAssist

import Foundation
import OSLog

/// Scans system and user cache directories for reclaimable space.
struct CacheScanner: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "CacheScanner")
    private let diskCalculator = DiskUsageCalculator()

    static let cachePaths: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return ["\(home)/Library/Caches", "/Library/Caches"]
    }()

    func scan(paths: [String]? = nil) -> [JunkItem] {
        let targetPaths = paths ?? Self.cachePaths
        var results: [JunkItem] = []

        for cachePath in targetPaths {
            guard FileManager.default.fileExists(atPath: cachePath) else { continue }
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: cachePath),
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for item in contents {
                let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let modDate = try? item.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let size: UInt64 = isDir ? diskCalculator.calculateDirectorySize(at: item.path) : diskCalculator.fileSize(at: item.path)
                guard size > 0 else { continue }

                let severity: JunkSeverity = cachePath.hasPrefix("/Library") ? .caution : .safe
                results.append(JunkItem(path: item.path, name: item.lastPathComponent, size: size,
                    category: .caches, severity: severity, lastModified: modDate, isDirectory: isDir))
            }
        }
        return results.sorted { $0.size > $1.size }
    }
}
