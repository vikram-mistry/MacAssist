// LaunchAgentItem.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation

/// Represents a launch agent or daemon discovered on the system.
struct LaunchAgentItem: Identifiable, Codable, Sendable {
    let id: UUID
    let label: String
    let plistPath: String
    let executablePath: String?
    let kind: LaunchAgentKind
    var status: LaunchAgentStatus
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        label: String,
        plistPath: String,
        executablePath: String? = nil,
        kind: LaunchAgentKind,
        status: LaunchAgentStatus = .unknown,
        isSelected: Bool = false
    ) {
        self.id = id
        self.label = label
        self.plistPath = plistPath
        self.executablePath = executablePath
        self.kind = kind
        self.status = status
        self.isSelected = isSelected
    }
}

/// Type of launch agent.
enum LaunchAgentKind: String, Codable, CaseIterable, Sendable {
    case userAgent = "User Agent"
    case systemAgent = "System Agent"
    case systemDaemon = "System Daemon"

    var icon: String {
        switch self {
        case .userAgent: return "person.circle"
        case .systemAgent: return "gearshape.circle"
        case .systemDaemon: return "server.rack"
        }
    }
}

/// Running status of a launch agent.
enum LaunchAgentStatus: String, Codable, Sendable {
    case running = "Running"
    case stopped = "Stopped"
    case loaded = "Loaded"
    case unloaded = "Unloaded"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .running, .loaded: return "green"
        case .stopped, .unloaded: return "orange"
        case .unknown: return "gray"
        }
    }
}

/// Login item representation.
struct LoginItem: Identifiable, Sendable {
    let id: UUID
    let name: String
    let bundleIdentifier: String?
    let path: String?
    let plistPath: String?
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String? = nil,
        path: String? = nil,
        plistPath: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.plistPath = plistPath
        self.isEnabled = isEnabled
    }
}
