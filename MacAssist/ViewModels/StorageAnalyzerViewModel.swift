// StorageAnalyzerViewModel.swift
// MacAssist

import Foundation
import OSLog

@Observable @MainActor
final class StorageAnalyzerViewModel {
    private let storageAnalyzer = StorageAnalyzer()
    private let diskCalculator = DiskUsageCalculator()
    private let largeFileScanner = LargeFileScanner()

    var storageTree: StorageNode?
    var topDirectories: [StorageNode] = []
    var fileDistribution: [FileTypeDistribution] = []
    var largeFiles: [LargeFile] = []
    var isAnalyzing = false
    var statusMessage = "Ready to analyze"
    var selectedThreshold: FileSizeThreshold = .mb500
    var displayMode: DisplayMode = .treemap
    var progress: Double = 0

    enum DisplayMode: String, CaseIterable {
        case treemap = "Treemap"
        case fileList = "File List"
        case directoryTree = "Directory Tree"
    }

    var totalDiskSpace: UInt64 = 0
    var availableSpace: UInt64 = 0

    func analyze() async {
        isAnalyzing = true
        progress = 0
        statusMessage = "Analyzing storage…"

        // Step 1: Get disk info (10%).
        progress = 0.1
        totalDiskSpace = diskCalculator.totalDiskSpace()
        availableSpace = diskCalculator.availableDiskSpace()

        // Step 2: Build directory tree (10% → 60%).
        statusMessage = "Building directory tree…"
        progress = 0.15
        storageTree = await Task.detached { self.storageAnalyzer.analyzeStorage(maxDepth: 3) }.value
        progress = 0.6

        // Step 3: Find largest directories (60% → 80%).
        statusMessage = "Finding largest directories…"
        topDirectories = await Task.detached { self.storageAnalyzer.topDirectories() }.value
        progress = 0.8

        // Step 4: Calculate file distribution (80% → 100%).
        statusMessage = "Calculating file distribution…"
        fileDistribution = await Task.detached { self.storageAnalyzer.calculateFileTypeDistribution() }.value
        progress = 1.0

        isAnalyzing = false
        statusMessage = "Analysis complete"
    }

    func scanLargeFiles() async {
        isAnalyzing = true
        progress = 0
        statusMessage = "Scanning for large files…"
        let threshold = selectedThreshold.rawValue
        largeFiles = await Task.detached { self.largeFileScanner.scan(threshold: threshold) }.value
        progress = 1.0
        isAnalyzing = false
        statusMessage = "Found \(largeFiles.count) large files"
    }
}
