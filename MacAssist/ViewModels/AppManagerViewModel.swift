// AppManagerViewModel.swift
// MacAssist

import Foundation
import OSLog

@Observable @MainActor
final class AppManagerViewModel {
    private let appDiscovery = AppDiscoveryService()
    private let appUninstall = AppUninstallService()

    var applications: [ApplicationItem] = []
    var isLoading = false
    var isUninstalling = false
    var statusMessage = "Loading applications…"
    var searchText = ""
    var sortOrder: SortOrder = .name
    var lastUninstallResult: AppUninstallService.UninstallResult?
    var showUninstallResult = false

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case lastOpened = "Last Opened"
    }

    var filteredApps: [ApplicationItem] {
        var result = applications
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOrder {
        case .name: result.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .size: result.sort { $0.size > $1.size }
        case .lastOpened: result.sort { ($0.lastOpened ?? .distantPast) > ($1.lastOpened ?? .distantPast) }
        }
        return result
    }

    var totalAppsSize: UInt64 { applications.reduce(0) { $0 + $1.size } }

    func loadApplications() async {
        isLoading = true; statusMessage = "Scanning applications…"
        applications = await Task.detached { self.appDiscovery.discoverApplications() }.value
        isLoading = false; statusMessage = "\(applications.count) applications found"
    }

    func deepUninstall(app: ApplicationItem) async -> AppUninstallService.UninstallResult {
        isUninstalling = true; statusMessage = "Uninstalling \(app.name)…"
        let result = await Task.detached { self.appUninstall.deepUninstall(app: app) }.value
        applications.removeAll { $0.id == app.id }
        isUninstalling = false
        statusMessage = "Uninstalled \(app.name) — freed \(FileSizeFormatter.format(result.totalFreedBytes))"
        return result
    }

    func previewUninstall(app: ApplicationItem) async -> [(path: String, size: UInt64, exists: Bool)] {
        await Task.detached { self.appUninstall.findAssociatedFiles(for: app) }.value
    }
}
