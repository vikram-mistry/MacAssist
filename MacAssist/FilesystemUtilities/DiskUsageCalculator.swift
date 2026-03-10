// DiskUsageCalculator.swift
// MacAssist

import Foundation
import OSLog

/// Calculates disk usage for files and directories.
struct DiskUsageCalculator: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "DiskUsageCalculator")

    /// Calculates total size of a directory recursively.
    func calculateDirectorySize(at path: String) -> UInt64 {
        let url = URL(fileURLWithPath: path)
        var totalSize: UInt64 = 0
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isRegularFileKey]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: Set(keys)),
               values.isRegularFile == true {
                totalSize += UInt64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
            }
        }
        return totalSize
    }

    /// Gets the file size of a single file.
    func fileSize(at path: String) -> UInt64 {
        (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? UInt64 ?? 0
    }

    /// Gets available disk space.
    func availableDiskSpace() -> UInt64 {
        let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(
            forKeys: [.volumeAvailableCapacityForImportantUsageKey]
        )
        return UInt64(values?.volumeAvailableCapacityForImportantUsage ?? 0)
    }

    /// Gets total disk space.
    func totalDiskSpace() -> UInt64 {
        let values = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(
            forKeys: [.volumeTotalCapacityKey]
        )
        return UInt64(values?.volumeTotalCapacity ?? 0)
    }

    /// Builds a StorageNode tree from a directory.
    func buildStorageTree(at path: String, maxDepth: Int = 3, currentDepth: Int = 0) -> StorageNode {
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent

        guard currentDepth < maxDepth else {
            let size = calculateDirectorySize(at: path)
            return StorageNode(name: name, path: path, size: size, isDirectory: true, depth: currentDepth)
        }

        var children: [StorageNode] = []
        var totalSize: UInt64 = 0

        if let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for item in contents {
                let values = try? item.resourceValues(forKeys: [.isDirectoryKey, .totalFileAllocatedSizeKey])
                let isDir = values?.isDirectory ?? false

                if isDir {
                    let child = buildStorageTree(at: item.path, maxDepth: maxDepth, currentDepth: currentDepth + 1)
                    children.append(child)
                    totalSize += child.size
                } else {
                    let size = UInt64(values?.totalFileAllocatedSize ?? 0)
                    let ext = item.pathExtension.lowercased()
                    children.append(StorageNode(
                        name: item.lastPathComponent, path: item.path, size: size,
                        isDirectory: false, depth: currentDepth + 1, fileType: ext.isEmpty ? nil : ext
                    ))
                    totalSize += size
                }
            }
        }

        children.sort { $0.size > $1.size }
        return StorageNode(name: name, path: path, size: totalSize, isDirectory: true, children: children, depth: currentDepth)
    }
}
