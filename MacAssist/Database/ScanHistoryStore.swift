// ScanHistoryStore.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation
import OSLog

/// Lightweight JSON-backed data store for scan history and metadata.
actor ScanHistoryStore {
    private let logger = Logger(subsystem: "com.vikram.macassist", category: "ScanHistoryStore")
    private let storageURL: URL
    private var history: ScanHistory

    struct ScanHistory: Codable {
        var scans: [ScanRecord]
        var lastScanTimestamp: Date?
    }

    struct ScanRecord: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let scanType: String
        let totalItemsFound: Int
        let totalSizeBytes: UInt64
        let itemsCleaned: Int
        let sizeCleaned: UInt64
        let duration: TimeInterval
    }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let macAssistDir = appSupport.appendingPathComponent("MacAssist", isDirectory: true)

        // Ensure directory exists.
        try? FileManager.default.createDirectory(at: macAssistDir, withIntermediateDirectories: true)

        self.storageURL = macAssistDir.appendingPathComponent("scan_history.json")

        // Load existing data.
        if let data = try? Data(contentsOf: storageURL),
           let decoded = try? JSONDecoder().decode(ScanHistory.self, from: data) {
            self.history = decoded
        } else {
            self.history = ScanHistory(scans: [], lastScanTimestamp: nil)
        }
    }

    /// Records a completed scan.
    func recordScan(
        type: String,
        itemsFound: Int,
        totalSize: UInt64,
        itemsCleaned: Int,
        sizeCleaned: UInt64,
        duration: TimeInterval
    ) {
        let record = ScanRecord(
            id: UUID(),
            timestamp: Date(),
            scanType: type,
            totalItemsFound: itemsFound,
            totalSizeBytes: totalSize,
            itemsCleaned: itemsCleaned,
            sizeCleaned: sizeCleaned,
            duration: duration
        )

        history.scans.append(record)
        history.lastScanTimestamp = Date()
        save()
    }

    /// Returns all scan records.
    func allRecords() -> [ScanRecord] {
        history.scans
    }

    /// Returns the most recent scan records.
    func recentRecords(limit: Int = 10) -> [ScanRecord] {
        Array(history.scans.suffix(limit))
    }

    /// Returns the last scan timestamp.
    func lastScanDate() -> Date? {
        history.lastScanTimestamp
    }

    /// Total space cleaned across all scans.
    func totalSpaceCleaned() -> UInt64 {
        history.scans.reduce(0) { $0 + $1.sizeCleaned }
    }

    /// Clears all scan history.
    func clearHistory() {
        history = ScanHistory(scans: [], lastScanTimestamp: nil)
        save()
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(history)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            logger.error("Failed to save scan history: \(error.localizedDescription)")
        }
    }
}
