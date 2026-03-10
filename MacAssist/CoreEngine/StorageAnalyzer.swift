// StorageAnalyzer.swift
// MacAssist

import Foundation
import OSLog

/// Deep storage analysis engine.
struct StorageAnalyzer: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "StorageAnalyzer")
    private let diskCalculator = DiskUsageCalculator()

    func analyzeStorage(maxDepth: Int = 3) -> StorageNode {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        return diskCalculator.buildStorageTree(at: homePath, maxDepth: maxDepth)
    }

    func calculateFileTypeDistribution() -> [FileTypeDistribution] {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        var typeMap: [String: (size: UInt64, count: Int)] = [:]
        var totalSize: UInt64 = 0

        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: homePath),
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: { _, _ in true }
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true else { continue }
            let size = UInt64(values.totalFileAllocatedSize ?? 0)
            let ext = fileURL.pathExtension.lowercased()
            let category = ext.isEmpty ? "Other" : ext
            var entry = typeMap[category] ?? (size: 0, count: 0)
            entry.size += size
            entry.count += 1
            typeMap[category] = entry
            totalSize += size
        }

        return typeMap.map { key, value in
            FileTypeDistribution(fileType: key, totalSize: value.size, fileCount: value.count,
                percentage: totalSize > 0 ? Double(value.size) / Double(totalSize) * 100 : 0)
        }.sorted { $0.totalSize > $1.totalSize }
    }

    func topDirectories(at path: String? = nil, limit: Int = 20) -> [StorageNode] {
        let scanPath = path ?? FileManager.default.homeDirectoryForCurrentUser.path
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: scanPath), includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var directories: [StorageNode] = []
        for item in contents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard isDir else { continue }
            let size = diskCalculator.calculateDirectorySize(at: item.path)
            directories.append(StorageNode(name: item.lastPathComponent, path: item.path, size: size, isDirectory: true, depth: 0))
        }
        return Array(directories.sorted { $0.size > $1.size }.prefix(limit))
    }
}
