// ScanResult.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation

/// Represents the aggregated result of a system scan.
struct ScanResult: Identifiable, Codable, Sendable {
    let id: UUID
    let timestamp: Date
    var totalSize: UInt64
    var itemCount: Int
    var categories: [ScanCategory]
    var status: ScanStatus

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        totalSize: UInt64 = 0,
        itemCount: Int = 0,
        categories: [ScanCategory] = [],
        status: ScanStatus = .pending
    ) {
        self.id = id
        self.timestamp = timestamp
        self.totalSize = totalSize
        self.itemCount = itemCount
        self.categories = categories
        self.status = status
    }
}

/// A category within a scan result (e.g., Caches, Logs, Developer junk).
struct ScanCategory: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let icon: String
    var totalSize: UInt64
    var items: [JunkItem]

    init(id: UUID = UUID(), name: String, icon: String, totalSize: UInt64 = 0, items: [JunkItem] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.totalSize = totalSize
        self.items = items
    }
}

/// Status of a scan operation.
enum ScanStatus: String, Codable, Sendable {
    case pending
    case scanning
    case completed
    case failed
    case cancelled
}
