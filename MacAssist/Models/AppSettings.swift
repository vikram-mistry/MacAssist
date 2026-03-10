// AppSettings.swift
// MacAssist

import Foundation
import SwiftUI

/// App-wide settings backed by UserDefaults.
@Observable @MainActor
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - General
    var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin") }
    }

    var showDockIcon: Bool {
        didSet { UserDefaults.standard.set(showDockIcon, forKey: "showDockIcon") }
    }

    // MARK: - Scanning
    var defaultScanDepth: Int {
        didSet { UserDefaults.standard.set(defaultScanDepth, forKey: "defaultScanDepth") }
    }

    var largeFileThreshold: Int {
        didSet { UserDefaults.standard.set(largeFileThreshold, forKey: "largeFileThresholdMB") }
    }

    var scanExclusions: [String] {
        didSet { UserDefaults.standard.set(scanExclusions, forKey: "scanExclusions") }
    }

    var skipHiddenFiles: Bool {
        didSet { UserDefaults.standard.set(skipHiddenFiles, forKey: "skipHiddenFiles") }
    }

    // MARK: - Cleanup
    var moveToTrashInsteadOfDelete: Bool {
        didSet { UserDefaults.standard.set(moveToTrashInsteadOfDelete, forKey: "moveToTrashInsteadOfDelete") }
    }

    var showCleanConfirmation: Bool {
        didSet { UserDefaults.standard.set(showCleanConfirmation, forKey: "showCleanConfirmation") }
    }

    var autoSelectSafeItems: Bool {
        didSet { UserDefaults.standard.set(autoSelectSafeItems, forKey: "autoSelectSafeItems") }
    }

    // MARK: - Notifications
    var enableScanReminders: Bool {
        didSet { UserDefaults.standard.set(enableScanReminders, forKey: "enableScanReminders") }
    }

    var reminderIntervalDays: Int {
        didSet { UserDefaults.standard.set(reminderIntervalDays, forKey: "reminderIntervalDays") }
    }

    // MARK: - Init
    private init() {
        let defaults = UserDefaults.standard

        // Register defaults.
        defaults.register(defaults: [
            "launchAtLogin": false,
            "showDockIcon": true,
            "defaultScanDepth": 3,
            "largeFileThresholdMB": 500,
            "scanExclusions": [String](),
            "skipHiddenFiles": true,
            "moveToTrashInsteadOfDelete": true,
            "showCleanConfirmation": true,
            "autoSelectSafeItems": true,
            "enableScanReminders": false,
            "reminderIntervalDays": 7
        ])

        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        self.showDockIcon = defaults.bool(forKey: "showDockIcon")
        self.defaultScanDepth = defaults.integer(forKey: "defaultScanDepth")
        self.largeFileThreshold = defaults.integer(forKey: "largeFileThresholdMB")
        self.scanExclusions = defaults.stringArray(forKey: "scanExclusions") ?? []
        self.skipHiddenFiles = defaults.bool(forKey: "skipHiddenFiles")
        self.moveToTrashInsteadOfDelete = defaults.bool(forKey: "moveToTrashInsteadOfDelete")
        self.showCleanConfirmation = defaults.bool(forKey: "showCleanConfirmation")
        self.autoSelectSafeItems = defaults.bool(forKey: "autoSelectSafeItems")
        self.enableScanReminders = defaults.bool(forKey: "enableScanReminders")
        self.reminderIntervalDays = defaults.integer(forKey: "reminderIntervalDays")
    }

    /// Resets all settings to defaults.
    func resetToDefaults() {
        launchAtLogin = false
        showDockIcon = true
        defaultScanDepth = 3
        largeFileThreshold = 500
        scanExclusions = []
        skipHiddenFiles = true
        moveToTrashInsteadOfDelete = true
        showCleanConfirmation = true
        autoSelectSafeItems = true
        enableScanReminders = false
        reminderIntervalDays = 7
    }
}
