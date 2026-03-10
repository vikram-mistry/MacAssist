// StorageNode.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation

/// Tree node representing a directory or file in the storage hierarchy.
/// Used for treemap visualization and expandable directory tree.
final class StorageNode: Identifiable, Sendable {
    let id: UUID
    let name: String
    let path: String
    let size: UInt64
    let isDirectory: Bool
    let children: [StorageNode]
    let depth: Int
    let fileType: String?

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        size: UInt64,
        isDirectory: Bool,
        children: [StorageNode] = [],
        depth: Int = 0,
        fileType: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.isDirectory = isDirectory
        self.children = children
        self.depth = depth
        self.fileType = fileType
    }

    /// Percentage of parent size.
    func percentage(of parentSize: UInt64) -> Double {
        guard parentSize > 0 else { return 0 }
        return Double(size) / Double(parentSize) * 100.0
    }
}

/// File type distribution for storage analysis.
struct FileTypeDistribution: Identifiable, Sendable {
    let id: UUID
    let fileType: String
    let totalSize: UInt64
    let fileCount: Int
    let percentage: Double

    init(id: UUID = UUID(), fileType: String, totalSize: UInt64, fileCount: Int, percentage: Double) {
        self.id = id
        self.fileType = fileType
        self.totalSize = totalSize
        self.fileCount = fileCount
        self.percentage = percentage
    }
}
