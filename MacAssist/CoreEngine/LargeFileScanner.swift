// LargeFileScanner.swift
// MacAssist

import Foundation
import OSLog

/// Scans user directories for files exceeding configurable size thresholds.
struct LargeFileScanner: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "LargeFileScanner")

    func scan(rootPath: String? = nil, threshold: UInt64 = FileSizeThreshold.mb500.rawValue) -> [LargeFile] {
        let scanPath = rootPath ?? FileManager.default.homeDirectoryForCurrentUser.path
        var results: [LargeFile] = []

        let keys: Set<URLResourceKey> = [.fileSizeKey, .totalFileAllocatedSizeKey, .isRegularFileKey,
            .contentAccessDateKey, .contentModificationDateKey]

        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: scanPath), includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: { _, _ in true }
        ) else { return results }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isRegularFile == true else { continue }
            let size = UInt64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
            guard size >= threshold else { continue }

            results.append(LargeFile(path: fileURL.path, name: fileURL.lastPathComponent, size: size,
                fileExtension: fileURL.pathExtension.lowercased(),
                lastAccessed: values.contentAccessDate, lastModified: values.contentModificationDate))
        }
        return results.sorted { $0.size > $1.size }
    }
}
