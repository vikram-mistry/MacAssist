// JunkCleanerViewModel.swift
// MacAssist

import Foundation
import OSLog

@Observable @MainActor
final class JunkCleanerViewModel {
    private let scanEngine = ScanEngine()
    private let deletionService = FileDeletionService()
    private let developerCleanupService = DeveloperCleanupService()

    var junkItems: [JunkItem] = []
    var isScanning = false
    var isCleaning = false
    var statusMessage = "Ready to scan"
    var selectedFilter: JunkCategory?
    var showSuccess = false
    var lastCleanedSize: UInt64 = 0
    var lastCleanedCount: Int = 0

    var filteredItems: [JunkItem] { selectedFilter.map { f in junkItems.filter { $0.category == f } } ?? junkItems }
    var totalJunkSize: UInt64 { junkItems.reduce(0) { $0 + $1.size } }
    var selectedSize: UInt64 { junkItems.filter(\.isSelected).reduce(0) { $0 + $1.size } }

    var categorySummary: [(category: JunkCategory, count: Int, size: UInt64)] {
        let grouped = Dictionary(grouping: junkItems) { $0.category }
        return JunkCategory.allCases.compactMap { cat in
            guard let items = grouped[cat], !items.isEmpty else { return nil }
            return (category: cat, count: items.count, size: items.reduce(0) { $0 + $1.size })
        }
    }

    func scan() async {
        isScanning = true; statusMessage = "Scanning for junk…"
        var items = await scanEngine.performJunkScan()
        let devItems = await Task.detached { self.developerCleanupService.scan() }.value
        items.append(contentsOf: devItems)
        junkItems = items.sorted { $0.size > $1.size }
        isScanning = false
        statusMessage = "Found \(junkItems.count) items — \(FileSizeFormatter.format(totalJunkSize))"
    }

    func cleanSelected() async {
        isCleaning = true; statusMessage = "Cleaning…"
        let selected = junkItems.filter(\.isSelected)
        let results = await Task.detached { self.deletionService.deleteItems(selected) }.value
        let freedBytes = results.filter(\.success).reduce(0) { $0 + $1.freedBytes }
        let cleanedPaths = Set(results.filter(\.success).map(\.path))
        let cleanedCount = cleanedPaths.count
        junkItems.removeAll() // Clear all items to return to empty home screen after success
        isCleaning = false
        statusMessage = "Cleaned \(FileSizeFormatter.format(freedBytes))"
        lastCleanedSize = freedBytes
        lastCleanedCount = cleanedCount
        showSuccess = true
    }

    func selectAll() { for i in junkItems.indices { junkItems[i].isSelected = true } }
    func deselectAll() { for i in junkItems.indices { junkItems[i].isSelected = false } }
}
