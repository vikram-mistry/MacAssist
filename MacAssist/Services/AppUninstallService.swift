// AppUninstallService.swift
// MacAssist

import Foundation
import OSLog

/// Deep application uninstall service with comprehensive leftover scanning.
struct AppUninstallService: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "AppUninstallService")
    private let deletionService = FileDeletionService()
    private let diskCalculator = DiskUsageCalculator()

    struct UninstallResult: Sendable {
        let appName: String
        let removedPaths: [String]
        let failedPaths: [String]
        let totalFreedBytes: UInt64
    }

    /// Comprehensively scans for ALL associated files using multiple discovery methods.
    func findAssociatedFiles(for app: ApplicationItem) -> [(path: String, size: UInt64, exists: Bool)] {
        var foundPaths = Set<String>()
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let bundleId = app.bundleIdentifier
        let appName = app.name

        // Use a strict matching algorithm instead of loose .contains()


        // Method 1: Scan well-known ~/Library subdirectories.
        let librarySubdirs = [
            "Application Support", "Caches", "Logs", "Preferences",
            "Containers", "Saved Application State", "WebKit",
            "HTTPStorages", "Cookies", "Group Containers",
            "Application Scripts", "LaunchAgents"
        ]

        for subdir in librarySubdirs {
            let dirPath = "\(home)/Library/\(subdir)"
            guard fm.fileExists(atPath: dirPath),
                  let contents = try? fm.contentsOfDirectory(atPath: dirPath) else { continue }

            for item in contents {
                if isAssociated(itemName: item, bundleId: bundleId, appName: appName) {
                    let fullPath = "\(dirPath)/\(item)"
                    if fullPath != app.installPath {
                        foundPaths.insert(fullPath)
                    }
                }
            }
        }

        // Method 2: Scan system Library paths.
        let systemPaths = [
            "/Library/LaunchDaemons",
            "/Library/LaunchAgents",
            "/Library/PrivilegedHelperTools",
            "/Library/Preferences",
            "/Library/Application Support"
        ]

        for sysPath in systemPaths {
            guard fm.fileExists(atPath: sysPath),
                  let contents = try? fm.contentsOfDirectory(atPath: sysPath) else { continue }

            for item in contents {
                if isAssociated(itemName: item, bundleId: bundleId, appName: appName) {
                    foundPaths.insert("\(sysPath)/\(item)")
                }
            }
        }

        // Method 3: Scan for dot-directories in home (e.g., ~/.docker/).
        if let homeContents = try? fm.contentsOfDirectory(atPath: home) {
            for item in homeContents where item.hasPrefix(".") {
                let cleanName = String(item.dropFirst()) // remove leading dot
                if isAssociated(itemName: cleanName, bundleId: bundleId, appName: appName) {
                    foundPaths.insert("\(home)/\(item)")
                }
            }
        }

        // Method 4: Use mdfind (Spotlight) to find any remaining files by bundle ID.
        let spotlightPaths = searchViaSpotlight(bundleId: bundleId)
        for path in spotlightPaths {
            if path != app.installPath && !path.hasPrefix("/System") {
                foundPaths.insert(path)
            }
        }

        // Method 5: Check some additional known patterns.
        let additionalPaths = [
            "\(home)/Library/Application Support/\(appName)",
            "\(home)/Library/Application Support/\(bundleId)",
            "\(home)/Library/Caches/\(bundleId)",
            "\(home)/Library/Preferences/\(bundleId).plist",
            "\(home)/Library/Containers/\(bundleId)",
            "\(home)/Library/Group Containers/\(bundleId)",
            "\(home)/Library/Saved Application State/\(bundleId).savedState",
            "\(home)/Library/HTTPStorages/\(bundleId)",
            "\(home)/Library/WebKit/\(bundleId)",
            "\(home)/Library/Cookies/\(bundleId).binarycookies",
            "\(home)/Library/Application Scripts/\(bundleId)",
            "\(home)/Library/Logs/\(appName)",
        ]
        for path in additionalPaths {
            foundPaths.insert(path)
        }

        // Build result with sizes and existence.
        let results: [(path: String, size: UInt64, exists: Bool)] = foundPaths.sorted().map { path in
            let exists = fm.fileExists(atPath: path)
            var size: UInt64 = 0
            if exists {
                var isDir: ObjCBool = false
                fm.fileExists(atPath: path, isDirectory: &isDir)
                size = isDir.boolValue ? diskCalculator.calculateDirectorySize(at: path) : diskCalculator.fileSize(at: path)
            }
            return (path: path, size: size, exists: exists)
        }

        Self.logger.info("Found \(results.filter(\.exists).count) existing associated files for \(app.name)")
        return results
    }

    /// Safely and strictly determines if a filename is associated with the app.
    private func isAssociated(itemName: String, bundleId: String, appName: String) -> Bool {
        let name = itemName.lowercased()
        let bId = bundleId.lowercased()
        let aName = appName.lowercased()

        // 1. Exact match or prefix match for bundle ID (e.g., com.docker.docker, com.docker.docker.plist)
        if name.hasPrefix(bId) { return true }

        // 2. Exact match or prefix match for App Name (with safe boundary)
        if name == aName || name.hasPrefix("\(aName).") || name.hasPrefix("\(aName) ") { return true }

        // 3. Clean app name (no spaces, no dashes)
        let cleanAppName = aName.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        if name == cleanAppName || name.hasPrefix("\(cleanAppName).") { return true }

        // 4. Sometimes it's vendor.appName (e.g., docker.vmnetd)
        let parts = bId.components(separatedBy: ".")
        if parts.count >= 3 {
            let vendor = parts[1]
            // Exclude overly generic vendors to prevent sweeping deletions.
            let genericVendors = ["apple", "google", "microsoft", "adobe", "com", "net", "org"]
            
            if !genericVendors.contains(vendor) && vendor.count > 2 {
                if name.hasPrefix("\(vendor).") && name.contains(cleanAppName) { return true }
            }
        }

        return false
    }

    /// Search for files via Spotlight/mdfind by bundle identifier.
    private func searchViaSpotlight(bundleId: String) -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemCFBundleIdentifier == '\(bundleId)'"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }
            return output.components(separatedBy: "\n").filter { !$0.isEmpty }
        } catch {
            Self.logger.error("mdfind failed: \(error.localizedDescription)")
            return []
        }
    }

    /// Deep uninstall — moves all files to Trash for safety.
    func deepUninstall(app: ApplicationItem) -> UninstallResult {
        var removedPaths: [String] = []
        var failedPaths: [String] = []
        var totalFreed: UInt64 = 0

        // Move app bundle to Trash.
        let appResult = deletionService.moveToTrash(at: app.installPath)
        if appResult.success {
            removedPaths.append(app.installPath)
            totalFreed += appResult.freedBytes
        } else {
            failedPaths.append(app.installPath)
        }

        // Find and remove associated files.
        let associated = findAssociatedFiles(for: app)
        for file in associated where file.exists {
            let result = deletionService.moveToTrash(at: file.path)
            if result.success {
                removedPaths.append(file.path)
                totalFreed += result.freedBytes
            } else {
                failedPaths.append(file.path)
            }
        }

        Self.logger.info("Uninstalled \(app.name): \(removedPaths.count) removed, \(failedPaths.count) failed, freed \(totalFreed) bytes")
        return UninstallResult(
            appName: app.name,
            removedPaths: removedPaths,
            failedPaths: failedPaths,
            totalFreedBytes: totalFreed
        )
    }
}
