// HelperProtocol.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation

/// XPC protocol for communication between the main app and the privileged helper tool.
@objc protocol HelperToolProtocol {
    /// Deletes a file or directory at the specified path with elevated privileges.
    func deleteItem(atPath path: String, withReply reply: @escaping (Bool, String?) -> Void)

    /// Checks if a path is accessible with current privileges.
    func checkAccess(atPath path: String, withReply reply: @escaping (Bool) -> Void)

    /// Gets the version of the helper tool.
    func getVersion(withReply reply: @escaping (String) -> Void)

    /// Clears system caches that require root access.
    func clearSystemCaches(withReply reply: @escaping (Bool, UInt64, String?) -> Void)

    /// Removes protected launch daemon plist.
    func removeLaunchDaemon(atPath path: String, withReply reply: @escaping (Bool, String?) -> Void)
}

/// Protocol for the main app side of the XPC connection.
@objc protocol HelperToolProgressProtocol {
    /// Reports progress from the helper tool.
    func progressUpdate(_ message: String, percentComplete: Double)
}
