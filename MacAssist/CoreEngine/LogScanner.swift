// LogScanner.swift
// MacAssist

import Foundation
import OSLog

/// Scans system and user log directories for reclaimable space.
struct LogScanner: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "LogScanner")
    private let diskCalculator = DiskUsageCalculator()

    static let logPaths: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return ["\(home)/Library/Logs", "/Library/Logs"]
    }()

    func scan(paths: [String]? = nil) -> [JunkItem] {
        let targetPaths = paths ?? Self.logPaths
        var results: [JunkItem] = []

        for logPath in targetPaths {
            guard FileManager.default.fileExists(atPath: logPath) else { continue }
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: logPath),
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for item in contents {
                let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                let modDate = try? item.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let size: UInt64 = isDir ? diskCalculator.calculateDirectorySize(at: item.path) : diskCalculator.fileSize(at: item.path)
                guard size > 0 else { continue }

                let severity: JunkSeverity = logPath.hasPrefix("/Library") ? .caution : .safe
                results.append(JunkItem(path: item.path, name: item.lastPathComponent, size: size,
                    category: .logs, severity: severity, lastModified: modDate, isDirectory: isDir))
            }
        }
        return results.sorted { $0.size > $1.size }
    }
}
