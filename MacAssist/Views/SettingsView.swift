// SettingsView.swift
// MacAssist

import SwiftUI
import ServiceManagement

/// Full-featured Settings view with General, Scanning, Cleanup, Notifications, and About sections.
struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var newExclusionPath = ""
    @State private var showResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header.
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings").font(.largeTitle.bold())
                        Text("Configure MacAssist preferences").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal)

                // General.
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("General", systemImage: "gearshape")
                            .font(.headline)

                        Divider()

                        Toggle("Launch MacAssist at Login", isOn: Binding(
                            get: { settings.launchAtLogin },
                            set: { newValue in
                                settings.launchAtLogin = newValue
                                configureLaunchAtLogin(newValue)
                            }
                        ))

                        Toggle("Show Dock Icon", isOn: $settings.showDockIcon)

                        HStack {
                            Text("Default Scan Depth")
                            Spacer()
                            Picker("", selection: $settings.defaultScanDepth) {
                                Text("2 levels").tag(2)
                                Text("3 levels").tag(3)
                                Text("4 levels").tag(4)
                                Text("5 levels").tag(5)
                            }
                            .frame(width: 130)
                        }
                    }
                }

                // Scanning.
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Scanning", systemImage: "magnifyingglass")
                            .font(.headline)

                        Divider()

                        HStack {
                            Text("Large File Threshold")
                            Spacer()
                            Picker("", selection: $settings.largeFileThreshold) {
                                Text("100 MB").tag(100)
                                Text("250 MB").tag(250)
                                Text("500 MB").tag(500)
                                Text("1 GB").tag(1024)
                                Text("5 GB").tag(5120)
                            }
                            .frame(width: 130)
                        }

                        Toggle("Skip Hidden Files & Folders", isOn: $settings.skipHiddenFiles)

                        // Scan exclusions.
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scan Exclusions")
                                .font(.subheadline.bold())
                            Text("Paths below will be skipped during scanning.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(settings.scanExclusions, id: \.self) { path in
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(.secondary)
                                    Text(path)
                                        .font(.caption.monospaced())
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        settings.scanExclusions.removeAll { $0 == path }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 2)
                            }

                            HStack {
                                Button {
                                    let panel = NSOpenPanel()
                                    panel.canChooseFiles = false
                                    panel.canChooseDirectories = true
                                    panel.allowsMultipleSelection = false
                                    panel.prompt = "Add Exclusion"
                                    if panel.runModal() == .OK, let url = panel.url {
                                        if !settings.scanExclusions.contains(url.path) {
                                            settings.scanExclusions.append(url.path)
                                        }
                                    }
                                } label: {
                                    Label("Add Folder…", systemImage: "plus.circle")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }

                // Cleanup.
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Cleanup", systemImage: "trash")
                            .font(.headline)

                        Divider()

                        Toggle("Move to Trash Instead of Permanent Delete", isOn: $settings.moveToTrashInsteadOfDelete)

                        Toggle("Show Confirmation Before Cleaning", isOn: $settings.showCleanConfirmation)

                        Toggle("Auto-select Safe Items After Scan", isOn: $settings.autoSelectSafeItems)
                    }
                }

                // Notifications.
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Notifications", systemImage: "bell")
                            .font(.headline)

                        Divider()

                        Toggle("Enable Scan Reminders", isOn: $settings.enableScanReminders)

                        if settings.enableScanReminders {
                            HStack {
                                Text("Remind Every")
                                Spacer()
                                Picker("", selection: $settings.reminderIntervalDays) {
                                    Text("3 days").tag(3)
                                    Text("7 days").tag(7)
                                    Text("14 days").tag(14)
                                    Text("30 days").tag(30)
                                }
                                .frame(width: 130)
                            }
                        }
                    }
                }

                // About.
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("About MacAssist", systemImage: "info.circle")
                            .font(.headline)

                        Text("MacAssist is a personal macOS system maintenance and storage intelligence tool. Keep your Mac running fast and clean.")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Divider()

                        HStack {
                            Text("Version").foregroundStyle(.secondary)
                            Spacer()
                            Text("1.0.0").font(.body.monospacedDigit())
                        }

                        HStack {
                            Text("macOS Requirement").foregroundStyle(.secondary)
                            Spacer()
                            Text("26.0+").font(.body.monospacedDigit())
                        }

                        HStack {
                            Text("Developer").foregroundStyle(.secondary)
                            Spacer()
                            Text("Vikram")
                        }

                        HStack {
                            Text("License").foregroundStyle(.secondary)
                            Spacer()
                            Text("Personal Use")
                        }
                    }
                }
            }
            .padding()
        }
        .alert("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This cannot be undone.")
        }
    }

    private func configureLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                // Silently fail — user may need to manage in System Settings.
            }
        }
    }
}
