// ScanEngine.swift
// MacAssist

import Foundation
import OSLog

/// Orchestrates all scanning operations, publishing progress to the UI layer.
@Observable @MainActor
final class ScanEngine {
    private let logger = Logger(subsystem: "com.vikram.macassist", category: "ScanEngine")
    private let junkScanner = JunkScanner()
    private let cacheScanner = CacheScanner()
    private let logScanner = LogScanner()
    private let largeFileScanner = LargeFileScanner()
    private let storageAnalyzer = StorageAnalyzer()

    var isScanning = false
    var progress: Double = 0
    var statusMessage = ""
    var currentScanResult: ScanResult?

    func performSmartScan() async -> ScanResult {
        isScanning = true
        progress = 0
        statusMessage = "Starting smart scan…"
        let startTime = Date()
        var allItems: [JunkItem] = []

        statusMessage = "Scanning caches…"
        let cacheItems = await Task.detached { self.cacheScanner.scan() }.value
        allItems.append(contentsOf: cacheItems)
        progress = 0.25

        statusMessage = "Scanning logs…"
        let logItems = await Task.detached { self.logScanner.scan() }.value
        allItems.append(contentsOf: logItems)
        progress = 0.50

        statusMessage = "Scanning application junk…"
        let junkItems = await Task.detached { self.junkScanner.scan() }.value
        let existingPaths = Set(allItems.map(\.path))
        allItems.append(contentsOf: junkItems.filter { !existingPaths.contains($0.path) })
        progress = 0.80

        statusMessage = "Finalizing results…"
        let categories = buildCategories(from: allItems)
        let totalSize = allItems.reduce(0) { $0 + $1.size }

        let result = ScanResult(timestamp: startTime, totalSize: totalSize, itemCount: allItems.count,
            categories: categories, status: .completed)
        progress = 1.0
        statusMessage = "Scan complete"
        isScanning = false
        currentScanResult = result
        return result
    }

    func performJunkScan() async -> [JunkItem] {
        isScanning = true
        statusMessage = "Scanning for junk files…"
        let items = await Task.detached { self.junkScanner.scan() }.value
        progress = 1.0
        statusMessage = "Junk scan complete"
        isScanning = false
        return items
    }

    func scanLargeFiles(threshold: UInt64 = FileSizeThreshold.mb500.rawValue) async -> [LargeFile] {
        isScanning = true
        statusMessage = "Scanning for large files…"
        let files = await Task.detached { self.largeFileScanner.scan(threshold: threshold) }.value
        progress = 1.0
        statusMessage = "Large file scan complete"
        isScanning = false
        return files
    }

    func analyzeStorage() async -> StorageNode {
        isScanning = true
        statusMessage = "Analyzing storage…"
        let tree = await Task.detached { self.storageAnalyzer.analyzeStorage() }.value
        progress = 1.0
        statusMessage = "Storage analysis complete"
        isScanning = false
        return tree
    }

    func cancelScan() { isScanning = false; statusMessage = "Scan cancelled"; progress = 0 }

    private func buildCategories(from items: [JunkItem]) -> [ScanCategory] {
        Dictionary(grouping: items) { $0.category }.map { category, categoryItems in
            ScanCategory(name: category.rawValue, icon: category.icon,
                totalSize: categoryItems.reduce(0) { $0 + $1.size },
                items: categoryItems.sorted { $0.size > $1.size })
        }.sorted { $0.totalSize > $1.totalSize }
    }
}
