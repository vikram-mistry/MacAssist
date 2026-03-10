// DeveloperCleanupService.swift
// MacAssist

import Foundation
import OSLog

/// Discovers and cleans developer-related files.
struct DeveloperCleanupService: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "DeveloperCleanupService")
    private let diskCalculator = DiskUsageCalculator()
    private let deletionService = FileDeletionService()

    struct DeveloperPaths {
        static let derivedData = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Developer/Xcode/DerivedData"
        static let archives = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Developer/Xcode/Archives"
        static let simulators = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Developer/CoreSimulator"
        static let swiftPackageCache = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Caches/org.swift.swiftpm"
        static var all: [String] { [derivedData, archives, simulators, swiftPackageCache] }
    }

    func scan() -> [JunkItem] {
        var items: [JunkItem] = []
        items.append(contentsOf: scanDeveloperDirectory(DeveloperPaths.derivedData))
        items.append(contentsOf: scanDeveloperDirectory(DeveloperPaths.archives))
        items.append(contentsOf: scanDeveloperDirectory(DeveloperPaths.simulators))
        items.append(contentsOf: scanDeveloperDirectory(DeveloperPaths.swiftPackageCache))
        return items
    }

    private func scanDeveloperDirectory(_ path: String) -> [JunkItem] {
        guard FileManager.default.fileExists(atPath: path),
              let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else { return [] }
        return contents.compactMap { item -> JunkItem? in
            let itemPath = "\(path)/\(item)"
            let size = diskCalculator.calculateDirectorySize(at: itemPath)
            guard size > 0 else { return nil }
            return JunkItem(path: itemPath, name: item, size: size, category: .developer,
                severity: path == DeveloperPaths.archives ? .caution : .safe, isDirectory: true)
        }.sorted { $0.size > $1.size }
    }

    func clean(items: [JunkItem]) -> UInt64 {
        items.filter(\.isSelected).reduce(0) { total, item in
            let result = deletionService.deleteItem(at: item.path)
            return total + (result.success ? result.freedBytes : 0)
        }
    }
}
