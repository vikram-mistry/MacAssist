// SmartCleanViewModel.swift
// MacAssist

import Foundation
import OSLog

@Observable @MainActor
final class SmartCleanViewModel {
    private let scanEngine = ScanEngine()
    private let deletionService = FileDeletionService()
    private let scanHistoryStore = ScanHistoryStore()

    var scanResult: ScanResult?
    var isScanning = false
    var isCleaning = false
    var progress: Double = 0
    var statusMessage = "Ready to scan"
    var showSuccess = false
    var lastCleanedSize: UInt64 = 0
    var lastCleanedCount: Int = 0

    var totalReclaimable: UInt64 { scanResult?.totalSize ?? 0 }
    var selectedItemCount: Int { scanResult?.categories.flatMap(\.items).filter(\.isSelected).count ?? 0 }
    var selectedSize: UInt64 { scanResult?.categories.flatMap(\.items).filter(\.isSelected).reduce(0) { $0 + $1.size } ?? 0 }

    func startScan() async {
        isScanning = true; progress = 0; statusMessage = "Scanning…"
        let result = await scanEngine.performSmartScan()
        scanResult = result
        isScanning = false
        statusMessage = "Scan complete — \(FileSizeFormatter.format(result.totalSize)) reclaimable"
        progress = 1.0
    }

    func cleanSelected() async {
        guard let result = scanResult else { return }
        isCleaning = true; statusMessage = "Cleaning…"
        let selectedItems = result.categories.flatMap(\.items).filter(\.isSelected)
        let startTime = Date()

        let deletionResults = await Task.detached { self.deletionService.deleteItems(selectedItems) }.value
        let freedBytes = deletionResults.filter(\.success).reduce(0) { $0 + $1.freedBytes }
        let cleanedCount = deletionResults.filter(\.success).count

        await scanHistoryStore.recordScan(type: "Smart Clean", itemsFound: selectedItems.count,
            totalSize: selectedSize, itemsCleaned: cleanedCount, sizeCleaned: freedBytes,
            duration: Date().timeIntervalSince(startTime))

        isCleaning = false
        statusMessage = "Cleaned \(FileSizeFormatter.format(freedBytes))"
        lastCleanedSize = freedBytes
        lastCleanedCount = cleanedCount
        showSuccess = true
        scanResult = nil
    }

    func toggleCategory(_ categoryId: UUID) {
        guard var result = scanResult, let index = result.categories.firstIndex(where: { $0.id == categoryId }) else { return }
        let allSelected = result.categories[index].items.allSatisfy(\.isSelected)
        for i in result.categories[index].items.indices { result.categories[index].items[i].isSelected = !allSelected }
        scanResult = result
    }

    func toggleItem(_ itemId: UUID) {
        guard var result = scanResult else { return }
        for catIndex in result.categories.indices {
            if let itemIndex = result.categories[catIndex].items.firstIndex(where: { $0.id == itemId }) {
                result.categories[catIndex].items[itemIndex].isSelected.toggle(); break
            }
        }
        scanResult = result
    }
}
