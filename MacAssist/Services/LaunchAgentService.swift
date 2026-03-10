// LaunchAgentService.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation
import OSLog

/// Inspects and manages Launch Agents and Daemons.
actor LaunchAgentService {
    private let logger = Logger(subsystem: "com.vikram.macassist", category: "LaunchAgentService")
    private let fileManager = FileManager.default

    /// Launch agent search paths.
    struct LaunchAgentPaths {
        static let userAgents: String = {
            FileManager.default.homeDirectoryForCurrentUser.path + "/Library/LaunchAgents"
        }()
        static let systemAgents = "/Library/LaunchAgents"
        static let systemDaemons = "/Library/LaunchDaemons"
    }

    /// Discovers all launch agents and daemons.
    func discoverAll() async -> [LaunchAgentItem] {
        var items: [LaunchAgentItem] = []

        items.append(contentsOf: await scanDirectory(LaunchAgentPaths.userAgents, kind: .userAgent))
        items.append(contentsOf: await scanDirectory(LaunchAgentPaths.systemAgents, kind: .systemAgent))
        items.append(contentsOf: await scanDirectory(LaunchAgentPaths.systemDaemons, kind: .systemDaemon))

        return items
    }

    /// Scans a launch agent directory.
    private func scanDirectory(_ path: String, kind: LaunchAgentKind) async -> [LaunchAgentItem] {
        guard fileManager.fileExists(atPath: path) else { return [] }
        var items: [LaunchAgentItem] = []

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            for file in contents where file.hasSuffix(".plist") {
                let plistPath = "\(path)/\(file)"
                if let item = parsePlist(at: plistPath, kind: kind) {
                    items.append(item)
                }
            }
        } catch {
            logger.error("Failed to scan \(path): \(error.localizedDescription)")
        }

        return items
    }

    /// Parses a launch agent/daemon plist file.
    private func parsePlist(at path: String, kind: LaunchAgentKind) -> LaunchAgentItem? {
        guard let data = fileManager.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }

        let label = plist["Label"] as? String ?? URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent

        var executablePath: String?
        if let program = plist["Program"] as? String {
            executablePath = program
        } else if let args = plist["ProgramArguments"] as? [String], let first = args.first {
            executablePath = first
        }

        return LaunchAgentItem(
            label: label,
            plistPath: path,
            executablePath: executablePath,
            kind: kind,
            status: .unknown
        )
    }

    /// Loads (enables) a launch agent.
    func load(item: LaunchAgentItem) async -> Bool {
        let result = await runLaunchctl("load", item.plistPath)
        return result
    }

    /// Unloads (disables) a launch agent.
    func unload(item: LaunchAgentItem) async -> Bool {
        let result = await runLaunchctl("unload", item.plistPath)
        return result
    }

    /// Removes a launch agent plist.
    func remove(item: LaunchAgentItem) async -> Bool {
        // First unload.
        _ = await unload(item: item)

        do {
            try fileManager.removeItem(atPath: item.plistPath)
            logger.info("Removed launch agent: \(item.label)")
            return true
        } catch {
            logger.error("Failed to remove \(item.plistPath): \(error.localizedDescription)")
            return false
        }
    }

    /// Runs a launchctl command.
    private func runLaunchctl(_ command: String, _ path: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = [command, path]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            logger.error("launchctl \(command) failed: \(error.localizedDescription)")
            return false
        }
    }
}
