// HelperConnection.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation
import OSLog

/// Manages the XPC connection to the privileged helper tool.
final class HelperConnection: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.vikram.macassist", category: "HelperConnection")
    private var connection: NSXPCConnection?

    static let helperMachServiceName = "com.vikram.macassist.helper"

    /// Establishes connection to the privileged helper tool.
    func connect() -> HelperToolProtocol? {
        if connection == nil {
            let newConnection = NSXPCConnection(machServiceName: Self.helperMachServiceName, options: .privileged)
            newConnection.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)
            newConnection.exportedInterface = NSXPCInterface(with: HelperToolProgressProtocol.self)

            newConnection.invalidationHandler = { [weak self] in
                self?.logger.info("XPC connection invalidated")
                self?.connection = nil
            }

            newConnection.interruptionHandler = { [weak self] in
                self?.logger.warning("XPC connection interrupted")
            }

            newConnection.resume()
            connection = newConnection
        }

        return connection?.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.logger.error("XPC proxy error: \(error.localizedDescription)")
        } as? HelperToolProtocol
    }

    /// Disconnects from the helper tool.
    func disconnect() {
        connection?.invalidate()
        connection = nil
    }

    /// Deletes a protected file via the helper tool.
    func deleteProtectedItem(at path: String) async -> Bool {
        guard let helper = connect() else {
            logger.error("Failed to connect to helper tool")
            return false
        }

        return await withCheckedContinuation { continuation in
            helper.deleteItem(atPath: path) { success, error in
                if let error = error {
                    self.logger.error("Helper deletion failed: \(error)")
                }
                continuation.resume(returning: success)
            }
        }
    }

    /// Checks access to a path via the helper tool.
    func checkProtectedAccess(at path: String) async -> Bool {
        guard let helper = connect() else { return false }

        return await withCheckedContinuation { continuation in
            helper.checkAccess(atPath: path) { accessible in
                continuation.resume(returning: accessible)
            }
        }
    }

    /// Gets the helper tool version.
    func helperVersion() async -> String? {
        guard let helper = connect() else { return nil }

        return await withCheckedContinuation { continuation in
            helper.getVersion { version in
                continuation.resume(returning: version)
            }
        }
    }
}
