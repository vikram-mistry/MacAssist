// HelperTool.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation
import OSLog

/// Privileged helper tool implementation using SMJobBless pattern.
/// This class would run as a separate executable registered via SMJobBless.
final class HelperTool: NSObject, HelperToolProtocol {
    private let logger = Logger(subsystem: "com.vikram.macassist.helper", category: "HelperTool")
    private let fileManager = FileManager.default

    /// Critical system paths that cannot be deleted even by the helper.
    private static let absolutelyProtectedPaths: Set<String> = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/Applications/Utilities",
        "/private/var/db/receipts"
    ]

    // MARK: - HelperToolProtocol

    func deleteItem(atPath path: String, withReply reply: @escaping (Bool, String?) -> Void) {
        logger.info("Helper: delete request for \(path)")

        // Safety check.
        for protectedPath in Self.absolutelyProtectedPaths {
            if path.hasPrefix(protectedPath) {
                reply(false, "Cannot delete system-critical path: \(path)")
                return
            }
        }

        guard fileManager.fileExists(atPath: path) else {
            reply(false, "File does not exist: \(path)")
            return
        }

        do {
            try fileManager.removeItem(atPath: path)
            logger.info("Helper: successfully deleted \(path)")
            reply(true, nil)
        } catch {
            logger.error("Helper: deletion failed for \(path): \(error.localizedDescription)")
            reply(false, error.localizedDescription)
        }
    }

    func checkAccess(atPath path: String, withReply reply: @escaping (Bool) -> Void) {
        let readable = fileManager.isReadableFile(atPath: path)
        let writable = fileManager.isWritableFile(atPath: path)
        reply(readable && writable)
    }

    func getVersion(withReply reply: @escaping (String) -> Void) {
        reply("1.0.0")
    }

    func clearSystemCaches(withReply reply: @escaping (Bool, UInt64, String?) -> Void) {
        let cachePath = "/Library/Caches"
        var freedBytes: UInt64 = 0

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: cachePath)
            for item in contents {
                let itemPath = "\(cachePath)/\(item)"
                // Skip Apple system caches.
                if item.hasPrefix("com.apple.") { continue }

                if let attributes = try? fileManager.attributesOfItem(atPath: itemPath) {
                    freedBytes += attributes[.size] as? UInt64 ?? 0
                }
                try fileManager.removeItem(atPath: itemPath)
            }
            reply(true, freedBytes, nil)
        } catch {
            reply(false, freedBytes, error.localizedDescription)
        }
    }

    func removeLaunchDaemon(atPath path: String, withReply reply: @escaping (Bool, String?) -> Void) {
        guard path.hasPrefix("/Library/LaunchDaemons/") else {
            reply(false, "Invalid path for launch daemon")
            return
        }

        // Unload first.
        let unloadProcess = Process()
        unloadProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        unloadProcess.arguments = ["unload", path]
        try? unloadProcess.run()
        unloadProcess.waitUntilExit()

        // Then delete.
        do {
            try fileManager.removeItem(atPath: path)
            reply(true, nil)
        } catch {
            reply(false, error.localizedDescription)
        }
    }
}
