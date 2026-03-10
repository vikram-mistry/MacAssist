// JunkScanner.swift
// MacAssist

import Foundation
import OSLog

/// General-purpose junk scanner combining cache, log, and rule-based scanning.
struct JunkScanner: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "JunkScanner")
    private let cacheScanner = CacheScanner()
    private let logScanner = LogScanner()
    private let diskCalculator = DiskUsageCalculator()

    func scan() -> [JunkItem] {
        var allItems: [JunkItem] = []
        allItems.append(contentsOf: cacheScanner.scan())
        allItems.append(contentsOf: logScanner.scan())
        allItems.append(contentsOf: scanAppSupport())
        allItems.append(contentsOf: scanTemporaryFiles())
        allItems.append(contentsOf: scanTrash())
        return allItems
    }

    private func scanAppSupport() -> [JunkItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let appSupportPath = "\(home)/Library/Application Support"
        var results: [JunkItem] = []
        guard FileManager.default.fileExists(atPath: appSupportPath),
              let apps = try? FileManager.default.contentsOfDirectory(atPath: appSupportPath) else { return results }

        for app in apps {
            let appDir = "\(appSupportPath)/\(app)"
            for cacheDir in ["Cache", "Caches", "cache", "GPUCache"] {
                let cachePath = "\(appDir)/\(cacheDir)"
                if FileManager.default.fileExists(atPath: cachePath) {
                    let size = diskCalculator.calculateDirectorySize(at: cachePath)
                    if size > 0 {
                        results.append(JunkItem(path: cachePath, name: "\(app) / \(cacheDir)", size: size,
                            category: .appSupport, severity: .safe, isDirectory: true))
                    }
                }
            }
            for logDir in ["Logs", "logs", "Log"] {
                let logPath = "\(appDir)/\(logDir)"
                if FileManager.default.fileExists(atPath: logPath) {
                    let size = diskCalculator.calculateDirectorySize(at: logPath)
                    if size > 0 {
                        results.append(JunkItem(path: logPath, name: "\(app) / \(logDir)", size: size,
                            category: .appSupport, severity: .safe, isDirectory: true))
                    }
                }
            }
        }
        return results
    }

    private func scanTemporaryFiles() -> [JunkItem] {
        var results: [JunkItem] = []
        let tmpPath = NSTemporaryDirectory()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: tmpPath), includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return results }

        for item in contents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let size: UInt64 = isDir ? diskCalculator.calculateDirectorySize(at: item.path) : diskCalculator.fileSize(at: item.path)
            guard size > 0 else { continue }
            results.append(JunkItem(path: item.path, name: item.lastPathComponent, size: size,
                category: .temporary, severity: .safe, isDirectory: isDir))
        }
        return results
    }

    private func scanTrash() -> [JunkItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let trashPath = "\(home)/.Trash"
        var results: [JunkItem] = []
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: trashPath), includingPropertiesForKeys: [.isDirectoryKey], options: []
        ) else { return results }

        for item in contents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let size: UInt64 = isDir ? diskCalculator.calculateDirectorySize(at: item.path) : diskCalculator.fileSize(at: item.path)
            guard size > 0 else { continue }
            results.append(JunkItem(path: item.path, name: item.lastPathComponent, size: size,
                category: .trash, severity: .safe, isDirectory: isDir))
        }
        return results
    }
}
