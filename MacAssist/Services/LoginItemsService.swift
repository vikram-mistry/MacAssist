// LoginItemsService.swift
// MacAssist

import Foundation
import ServiceManagement
import OSLog

/// Manages login/startup items using multiple discovery methods.
struct LoginItemsService: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "LoginItemsService")

    /// Discovers all login items.
    func discoverLoginItems() async -> [LoginItem] {
        var items: [LoginItem] = []
        var seenNames = Set<String>()

        // Method 1: Discover user LaunchAgents.
        let agentItems = await discoverViaLaunchAgents()
        for item in agentItems {
            if seenNames.insert(item.name).inserted {
                items.append(item)
            }
        }

        // Method 2: Scan plist files directly.
        let plistItems = discoverViaPlistFiles()
        for item in plistItems {
            if seenNames.insert(item.name).inserted {
                items.append(item)
            }
        }

        return items.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    /// Discover from LaunchAgents directory.
    private func discoverViaLaunchAgents() async -> [LoginItem] {
        let launchAgentService = LaunchAgentService()
        let agents = await launchAgentService.discoverAll()

        return agents.filter { $0.kind == .userAgent }.map { agent in
            let displayName = cleanDisplayName(from: agent.label)
            return LoginItem(
                name: displayName,
                bundleIdentifier: agent.label,
                path: agent.executablePath,
                plistPath: agent.plistPath,
                isEnabled: agent.status != .unloaded
            )
        }
    }

    /// Scan LaunchAgents plist files directly.
    private func discoverViaPlistFiles() -> [LoginItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let launchAgentsPath = "\(home)/Library/LaunchAgents"
        let fm = FileManager.default

        guard fm.fileExists(atPath: launchAgentsPath),
              let contents = try? fm.contentsOfDirectory(atPath: launchAgentsPath) else { return [] }

        var items: [LoginItem] = []
        for file in contents where file.hasSuffix(".plist") {
            let fullPlistPath = "\(launchAgentsPath)/\(file)"
            guard let data = fm.contents(atPath: fullPlistPath),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { continue }

            let label = plist["Label"] as? String ?? file.replacingOccurrences(of: ".plist", with: "")
            let displayName = cleanDisplayName(from: label)

            var execPath: String?
            if let program = plist["Program"] as? String {
                execPath = program
            } else if let args = plist["ProgramArguments"] as? [String], let first = args.first {
                execPath = first
            }

            let isLoaded = checkIfLoaded(label: label)

            items.append(LoginItem(
                name: displayName,
                bundleIdentifier: label,
                path: execPath,
                plistPath: fullPlistPath,
                isEnabled: isLoaded
            ))
        }
        return items
    }

    /// Check if a launch agent is currently loaded.
    private func checkIfLoaded(label: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["print", "gui/\(getuid())/\(label)"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return true
        }
    }

    private func cleanDisplayName(from label: String) -> String {
        let components = label.components(separatedBy: ".")
        if components.count >= 3 {
            let meaningful = components.dropFirst(2).joined(separator: " ")
            return meaningful.replacingOccurrences(of: "-", with: " ")
                .split(separator: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
        return label
    }

    /// Enable a login item using its plist path.
    func enableLoginItem(plistPath: String?, bundleIdentifier: String?) -> Bool {
        // Primary: use plist path with launchctl.
        if let plistPath, FileManager.default.fileExists(atPath: plistPath) {
            Self.logger.info("Loading via launchctl: \(plistPath)")
            return runLaunchctl(["load", "-w", plistPath])
        }

        // Fallback: SMAppService.
        if let bundleId = bundleIdentifier, #available(macOS 13.0, *) {
            let service = SMAppService.loginItem(identifier: bundleId)
            do {
                try service.register()
                return true
            } catch {
                Self.logger.error("SMAppService register failed: \(error.localizedDescription)")
            }
        }
        return false
    }

    /// Disable a login item using its plist path.
    func disableLoginItem(plistPath: String?, bundleIdentifier: String?) -> Bool {
        // Primary: use plist path with launchctl.
        if let plistPath, FileManager.default.fileExists(atPath: plistPath) {
            Self.logger.info("Unloading via launchctl: \(plistPath)")
            return runLaunchctl(["unload", "-w", plistPath])
        }

        // Fallback: SMAppService.
        if let bundleId = bundleIdentifier, #available(macOS 13.0, *) {
            let service = SMAppService.loginItem(identifier: bundleId)
            do {
                try service.unregister()
                return true
            } catch {
                Self.logger.error("SMAppService unregister failed: \(error.localizedDescription)")
            }
        }
        return false
    }

    private func runLaunchctl(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            Self.logger.info("launchctl \(arguments.joined(separator: " ")) → exit \(process.terminationStatus)")
            return process.terminationStatus == 0
        } catch {
            Self.logger.error("launchctl failed: \(error.localizedDescription)")
            return false
        }
    }
}
