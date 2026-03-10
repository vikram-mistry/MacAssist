// FileSizeFormatter.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation

/// Utility for formatting file sizes into human-readable strings.
enum FileSizeFormatter {
    /// Formats a byte count into a human-readable string (e.g., "1.5 GB").
    static func format(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Formats bytes into a short string without decimal places for compact display.
    static func formatCompact(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.zeroPadsFractionDigits = false
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Returns just the numeric value for a given byte count.
    static func numericValue(_ bytes: UInt64) -> (value: Double, unit: String) {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        return (value, units[unitIndex])
    }
}
