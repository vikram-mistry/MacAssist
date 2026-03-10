// FileDeletionService.swift
// MacAssist

import Foundation
import OSLog

/// Safe file deletion service with existence and system-critical checks.
struct FileDeletionService: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "FileDeletionService")
    private static let protectedPaths: Set<String> = [
        "/System", "/usr", "/bin", "/sbin", "/Library/Apple", "/private/var/db", "/private/var/folders"
    ]
    private let diskCalculator = DiskUsageCalculator()

    struct DeletionResult: Sendable {
        let path: String; let success: Bool; let error: String?; let freedBytes: UInt64
    }

    func deleteItem(at path: String) -> DeletionResult {
        guard FileManager.default.fileExists(atPath: path) else {
            return DeletionResult(path: path, success: false, error: "File does not exist", freedBytes: 0)
        }
        for pp in Self.protectedPaths { if path.hasPrefix(pp) {
            return DeletionResult(path: path, success: false, error: "System-critical path", freedBytes: 0)
        }}
        let size = calculateSize(at: path)
        do {
            try FileManager.default.removeItem(atPath: path)
            return DeletionResult(path: path, success: true, error: nil, freedBytes: size)
        } catch {
            return DeletionResult(path: path, success: false, error: error.localizedDescription, freedBytes: 0)
        }
    }

    func deleteItems(_ items: [JunkItem]) -> [DeletionResult] {
        items.filter(\.isSelected).map { deleteItem(at: $0.path) }
    }

    func moveToTrash(at path: String) -> DeletionResult {
        guard FileManager.default.fileExists(atPath: path) else {
            return DeletionResult(path: path, success: false, error: "File does not exist", freedBytes: 0)
        }
        let size = calculateSize(at: path)
        do {
            try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
            return DeletionResult(path: path, success: true, error: nil, freedBytes: size)
        } catch {
            return DeletionResult(path: path, success: false, error: error.localizedDescription, freedBytes: 0)
        }
    }

    func emptyTrash() -> DeletionResult {
        let trashPath = FileManager.default.homeDirectoryForCurrentUser.path + "/.Trash"
        let size = calculateSize(at: trashPath)
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: trashPath)
            for item in contents { try FileManager.default.removeItem(atPath: "\(trashPath)/\(item)") }
            return DeletionResult(path: trashPath, success: true, error: nil, freedBytes: size)
        } catch {
            return DeletionResult(path: trashPath, success: false, error: error.localizedDescription, freedBytes: 0)
        }
    }

    private func calculateSize(at path: String) -> UInt64 {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
            return diskCalculator.calculateDirectorySize(at: path)
        }
        return diskCalculator.fileSize(at: path)
    }
}
