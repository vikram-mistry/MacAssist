// DuplicateFinderService.swift
// MacAssist

import Foundation
import CryptoKit
import OSLog

/// Service that finds duplicate files using a two-pass approach:
/// 1. Group files by size.
/// 2. Compute SHA256 hash only for size-matched files.
struct DuplicateFinderService: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "DuplicateFinderService")

    /// Minimum file size to consider (skip tiny files).
    static let defaultMinSize: UInt64 = 1024 // 1 KB

    /// Result of the scan.
    struct ScanResult: Sendable {
        let groups: [DuplicateGroup]
        let totalFilesScanned: Int
        let totalDuplicates: Int
        let totalWastedSpace: UInt64
    }

    /// Scan a directory for duplicate files.
    func scan(
        at path: String,
        minSize: UInt64 = defaultMinSize,
        excludedPaths: [String] = [],
        progressHandler: @Sendable (String, Double) -> Void = { _, _ in }
    ) -> ScanResult {
        let fm = FileManager.default
        let url = URL(fileURLWithPath: path)

        // Phase 1: Enumerate all files and group by size.
        progressHandler("Scanning files…", 0.1)
        var sizeMap: [UInt64: [URL]] = [:]
        var totalFiles = 0

        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            return ScanResult(groups: [], totalFilesScanned: 0, totalDuplicates: 0, totalWastedSpace: 0)
        }

        let excludedSet = Set(excludedPaths)

        for case let fileURL as URL in enumerator {
            // Skip excluded paths.
            if excludedSet.contains(where: { fileURL.path.hasPrefix($0) }) { continue }

            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true else { continue }

            let fileSize = UInt64(values.fileSize ?? 0)
            guard fileSize >= minSize else { continue }

            sizeMap[fileSize, default: []].append(fileURL)
            totalFiles += 1
        }

        // Filter to only sizes with multiple files.
        let candidates = sizeMap.filter { $0.value.count > 1 }
        progressHandler("Found \(candidates.count) size groups to hash…", 0.3)

        // Phase 2: Hash files within each size group.
        var duplicateGroups: [DuplicateGroup] = []
        let totalCandidateGroups = candidates.count
        var processedGroups = 0

        for (fileSize, urls) in candidates {
            var hashMap: [String: [URL]] = [:]

            for fileURL in urls {
                if let hash = computePartialHash(for: fileURL, fileSize: fileSize) {
                    hashMap[hash, default: []].append(fileURL)
                }
            }

            // Create DuplicateGroups for hashes with multiple files.
            for (hash, matchingURLs) in hashMap where matchingURLs.count > 1 {
                let files = matchingURLs.map { fileURL -> DuplicateFileItem in
                    let modDate = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                    return DuplicateFileItem(
                        path: fileURL.path,
                        name: fileURL.lastPathComponent,
                        folderPath: fileURL.deletingLastPathComponent().path,
                        size: fileSize,
                        modificationDate: modDate,
                        isSelected: false
                    )
                }
                duplicateGroups.append(DuplicateGroup(hash: hash, fileSize: fileSize, files: files))
            }

            processedGroups += 1
            let progress = 0.3 + 0.7 * Double(processedGroups) / Double(max(totalCandidateGroups, 1))
            progressHandler("Hashing: \(processedGroups)/\(totalCandidateGroups) groups…", progress)
        }

        // Sort groups by wasted space (largest first).
        duplicateGroups.sort { $0.wastedSpace > $1.wastedSpace }

        let totalDuplicates = duplicateGroups.reduce(0) { $0 + $1.count - 1 }
        let totalWasted = duplicateGroups.reduce(0 as UInt64) { $0 + $1.wastedSpace }

        Self.logger.info("Scan complete: \(totalFiles) files, \(duplicateGroups.count) duplicate groups, \(totalDuplicates) duplicates")

        return ScanResult(
            groups: duplicateGroups,
            totalFilesScanned: totalFiles,
            totalDuplicates: totalDuplicates,
            totalWastedSpace: totalWasted
        )
    }

    /// Compute a hash for a file. Uses partial hashing for large files for performance.
    private func computePartialHash(for url: URL, fileSize: UInt64) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()

        if fileSize <= 1_048_576 { // 1 MB — hash entire file.
            guard let data = try? handle.readToEnd() else { return nil }
            hasher.update(data: data)
        } else {
            // Hash first 512KB + last 512KB for performance.
            let chunkSize = 524_288 // 512 KB

            guard let headData = try? handle.read(upToCount: chunkSize) else { return nil }
            hasher.update(data: headData)

            // Seek to end.
            let tailOffset = fileSize - UInt64(chunkSize)
            try? handle.seek(toOffset: tailOffset)
            guard let tailData = try? handle.read(upToCount: chunkSize) else { return nil }
            hasher.update(data: tailData)

            // Include file size to reduce collisions.
            withUnsafeBytes(of: fileSize) { hasher.update(bufferPointer: $0) }
        }

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
