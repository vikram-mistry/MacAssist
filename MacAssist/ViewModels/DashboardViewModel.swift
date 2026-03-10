// DashboardViewModel.swift
// MacAssist

import Foundation
import OSLog

/// Category for the Mac-style storage breakdown bar.
struct StorageCategory: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let size: UInt64
    let colorName: String // Use named color for SwiftUI
}

@Observable @MainActor
final class DashboardViewModel {
    private let diskCalculator = DiskUsageCalculator()
    private let scanHistoryStore = ScanHistoryStore()

    var totalDiskSpace: UInt64 = 0
    var availableSpace: UInt64 = 0
    var usedSpace: UInt64 = 0
    var usedPercentage: Double = 0
    var lastScanDate: Date?
    var totalSpaceCleaned: UInt64 = 0
    var recentScans: [ScanHistoryStore.ScanRecord] = []
    var isLoading = true
    var storageBreakdown: [StorageCategory] = []

    func loadDashboard() async {
        isLoading = true
        totalDiskSpace = diskCalculator.totalDiskSpace()
        availableSpace = diskCalculator.availableDiskSpace()
        usedSpace = totalDiskSpace > availableSpace ? totalDiskSpace - availableSpace : 0
        usedPercentage = totalDiskSpace > 0 ? Double(usedSpace) / Double(totalDiskSpace) * 100 : 0
        lastScanDate = await scanHistoryStore.lastScanDate()
        totalSpaceCleaned = await scanHistoryStore.totalSpaceCleaned()
        recentScans = await scanHistoryStore.recentRecords(limit: 5)

        // Calculate storage breakdown on background thread.
        let calculator = diskCalculator
        storageBreakdown = await Task.detached {
            Self.calculateStorageBreakdown(calculator: calculator)
        }.value

        isLoading = false
    }

    /// Calculate storage breakdown by category, similar to macOS System Settings.
    nonisolated private static func calculateStorageBreakdown(calculator: DiskUsageCalculator) -> [StorageCategory] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fm = FileManager.default

        struct CategoryDef {
            let name: String
            let paths: [String]
            let colorName: String
        }

        let categories: [CategoryDef] = [
            CategoryDef(name: "Applications", paths: ["/Applications", "\(home)/Applications"], colorName: "blue"),
            CategoryDef(name: "Photos", paths: ["\(home)/Pictures"], colorName: "purple"),
            CategoryDef(name: "Movies", paths: ["\(home)/Movies"], colorName: "red"),
            CategoryDef(name: "Music", paths: ["\(home)/Music"], colorName: "pink"),
            CategoryDef(name: "Documents", paths: ["\(home)/Documents", "\(home)/Desktop"], colorName: "yellow"),
            CategoryDef(name: "Downloads", paths: ["\(home)/Downloads"], colorName: "green"),
            CategoryDef(name: "Developer", paths: ["\(home)/Library/Developer"], colorName: "orange"),
            CategoryDef(name: "Mail", paths: ["\(home)/Library/Mail"], colorName: "cyan"),
        ]

        var results: [StorageCategory] = []
        var accounted: UInt64 = 0

        for cat in categories {
            var catSize: UInt64 = 0
            for path in cat.paths {
                guard fm.fileExists(atPath: path) else { continue }
                catSize += calculator.calculateDirectorySize(at: path)
            }
            if catSize > 0 {
                results.append(StorageCategory(name: cat.name, size: catSize, colorName: cat.colorName))
                accounted += catSize
            }
        }

        // System & Other = used space - accounted categories.
        let total = calculator.totalDiskSpace()
        let available = calculator.availableDiskSpace()
        let used = total > available ? total - available : 0
        if used > accounted {
            results.append(StorageCategory(name: "System & Other", size: used - accounted, colorName: "gray"))
        }

        return results.sorted { $0.size > $1.size }
    }
}
