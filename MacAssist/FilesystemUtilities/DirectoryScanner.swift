// DirectoryScanner.swift
// MacAssist

import Foundation
import OSLog

/// High-performance directory scanner that streams results.
struct DirectoryScanner: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "DirectoryScanner")

    /// Recursively scans a directory and returns all file URLs.
    func scanDirectory(at path: String, recursive: Bool = true) -> [URL] {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else { return [] }

        var results: [URL] = []
        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey]

        if recursive {
            guard let enumerator = FileManager.default.enumerator(
                at: url, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles],
                errorHandler: { _, _ in true }
            ) else { return [] }

            for case let fileURL as URL in enumerator {
                results.append(fileURL)
            }
        } else {
            results = (try? FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
            )) ?? []
        }
        return results
    }

    /// Streams directory contents as an AsyncStream for progressive UI updates.
    func streamDirectory(at path: String) -> AsyncStream<URL> {
        AsyncStream { continuation in
            let urls = scanDirectory(at: path)
            for url in urls {
                continuation.yield(url)
            }
            continuation.finish()
        }
    }

    /// Scans and returns immediate children of a directory with size info.
    func scanImmediateChildren(at path: String) -> [(url: URL, isDirectory: Bool, size: UInt64)] {
        let url = URL(fileURLWithPath: path)
        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey, .totalFileAllocatedSizeKey]

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: keys, options: []
        ) else { return [] }

        return contents.compactMap { item in
            guard let values = try? item.resourceValues(forKeys: Set(keys)) else { return nil }
            let isDir = values.isDirectory ?? false
            let size = UInt64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            return (url: item, isDirectory: isDir, size: size)
        }
    }
}
