// LargeFile.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation

/// Represents a large file detected above a configurable size threshold.
struct LargeFile: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let path: String
    let name: String
    let size: UInt64
    let fileExtension: String
    let lastAccessed: Date?
    let lastModified: Date?
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        path: String,
        name: String,
        size: UInt64,
        fileExtension: String = "",
        lastAccessed: Date? = nil,
        lastModified: Date? = nil,
        isSelected: Bool = false
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.size = size
        self.fileExtension = fileExtension
        self.lastAccessed = lastAccessed
        self.lastModified = lastModified
        self.isSelected = isSelected
    }
}

/// Configurable threshold for large file detection.
enum FileSizeThreshold: UInt64, CaseIterable, Sendable {
    case mb500 = 524_288_000       // 500 MB
    case gb1   = 1_073_741_824     // 1 GB
    case gb5   = 5_368_709_120     // 5 GB

    var displayName: String {
        switch self {
        case .mb500: return "500 MB"
        case .gb1: return "1 GB"
        case .gb5: return "5 GB"
        }
    }
}
