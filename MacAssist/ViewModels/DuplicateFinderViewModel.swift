// DuplicateFinderViewModel.swift
// MacAssist

import Foundation
import OSLog

@Observable @MainActor
final class DuplicateFinderViewModel {
    private let duplicateFinderService = DuplicateFinderService()
    private let deletionService = FileDeletionService()

    var duplicateGroups: [DuplicateGroup] = []
    var isScanning = false
    var isDeleting = false
    var progress: Double = 0
    var statusMessage = "Select a folder to scan for duplicates"
    var scanPath: String = FileManager.default.homeDirectoryForCurrentUser.path
    var totalFilesScanned = 0
    var totalDuplicates = 0
    var totalWastedSpace: UInt64 = 0
    var showDeleteResult = false
    var deleteResultMessage = ""

    // MARK: - Computed

    var selectedCount: Int {
        duplicateGroups.flatMap(\.files).filter(\.isSelected).count
    }

    var selectedSize: UInt64 {
        duplicateGroups.flatMap(\.files).filter(\.isSelected).reduce(0) { $0 + $1.size }
    }

    var hasResults: Bool { !duplicateGroups.isEmpty }

    // MARK: - Scan

    func scan() async {
        isScanning = true
        progress = 0
        statusMessage = "Scanning for duplicates…"
        duplicateGroups = []

        let path = scanPath
        let excludedPaths = AppSettings.shared.scanExclusions

        let result = await Task.detached { [self] in
            self.duplicateFinderService.scan(
                at: path,
                excludedPaths: excludedPaths
            ) { message, prog in
                Task { @MainActor in
                    self.statusMessage = message
                    self.progress = prog
                }
            }
        }.value

        duplicateGroups = result.groups
        totalFilesScanned = result.totalFilesScanned
        totalDuplicates = result.totalDuplicates
        totalWastedSpace = result.totalWastedSpace
        isScanning = false
        progress = 1.0

        if duplicateGroups.isEmpty {
            statusMessage = "No duplicates found in \(totalFilesScanned) files"
        } else {
            statusMessage = "Found \(totalDuplicates) duplicates in \(duplicateGroups.count) groups — \(FileSizeFormatter.format(totalWastedSpace)) wasted"
        }
    }

    /// Auto-select all duplicates except the oldest in each group.
    func autoSelectDuplicates() {
        var groups = duplicateGroups
        for groupIndex in groups.indices {
            let sorted = groups[groupIndex].files.sorted {
                ($0.modificationDate ?? .distantPast) < ($1.modificationDate ?? .distantPast)
            }
            for fileIndex in groups[groupIndex].files.indices {
                let file = groups[groupIndex].files[fileIndex]
                let isOldest = file.id == sorted.first?.id
                groups[groupIndex].files[fileIndex].isSelected = !isOldest
            }
        }
        duplicateGroups = groups
    }

    /// Deselect all files.
    func deselectAll() {
        var groups = duplicateGroups
        for groupIndex in groups.indices {
            for fileIndex in groups[groupIndex].files.indices {
                groups[groupIndex].files[fileIndex].isSelected = false
            }
        }
        duplicateGroups = groups
    }

    /// Toggle a specific file's selection.
    func toggleFile(_ fileId: UUID) {
        var groups = duplicateGroups
        for groupIndex in groups.indices {
            if let fileIndex = groups[groupIndex].files.firstIndex(where: { $0.id == fileId }) {
                groups[groupIndex].files[fileIndex].isSelected.toggle()
                break
            }
        }
        duplicateGroups = groups
    }

    /// Delete selected files (move to Trash).
    func deleteSelected() async {
        isDeleting = true
        statusMessage = "Moving selected files to Trash…"

        let selectedFiles = duplicateGroups.flatMap(\.files).filter(\.isSelected)
        var freedBytes: UInt64 = 0
        var deletedCount = 0
        var failedCount = 0

        for file in selectedFiles {
            let result = await Task.detached {
                self.deletionService.moveToTrash(at: file.path)
            }.value
            if result.success {
                freedBytes += result.freedBytes
                deletedCount += 1
            } else {
                failedCount += 1
            }
        }

        // Remove deleted files from groups.
        let deletedPaths = Set(selectedFiles.filter { file in
            duplicateGroups.flatMap(\.files).contains(where: { $0.path == file.path })
        }.map(\.path))

        var groups = duplicateGroups
        for groupIndex in groups.indices.reversed() {
            groups[groupIndex].files.removeAll { deletedPaths.contains($0.path) && !FileManager.default.fileExists(atPath: $0.path) }
            if groups[groupIndex].files.count <= 1 {
                groups.remove(at: groupIndex)
            }
        }
        duplicateGroups = groups

        isDeleting = false
        deleteResultMessage = "Moved \(deletedCount) files to Trash.\nFreed \(FileSizeFormatter.format(freedBytes))."
        if failedCount > 0 {
            deleteResultMessage += "\n\(failedCount) files could not be removed."
        }
        showDeleteResult = true
        statusMessage = "Deleted \(deletedCount) files — freed \(FileSizeFormatter.format(freedBytes))"
    }
}
