// AppManagerView.swift
// MacAssist
//
// Created by MacAssist on 2026.

import SwiftUI
import AppKit

/// Application Manager view with search, sorting, and deep uninstall.
struct AppManagerView: View {
    @State private var viewModel = AppManagerViewModel()
    @State private var selectedApp: ApplicationItem?
    @State private var associatedFiles: [(path: String, size: UInt64, exists: Bool)] = []
    @State private var isLoadingFiles = false
    @State private var expandedAppId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header.
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Applications")
                        .font(.largeTitle.bold())
                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Search and sort controls.
                HStack(spacing: 12) {
                    TextField("Search apps…", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)

                    Picker("Sort", selection: $viewModel.sortOrder) {
                        ForEach(AppManagerViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .frame(width: 130)
                }
            }
            .padding()

            Divider()

            if viewModel.isLoading {
                Spacer()
                ProgressView("Scanning applications…")
                Spacer()
            } else if viewModel.showUninstallResult, let result = viewModel.lastUninstallResult {
                CleanSuccessView(
                    title: "Application Uninstalled",
                    message: "Moved \(result.removedPaths.count) items to Trash and freed \(FileSizeFormatter.format(result.totalFreedBytes)) of storage space.",
                    iconName: "app.badge.checkmark"
                ) {
                    withAnimation { viewModel.showUninstallResult = false }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredApps) { app in
                            VStack(spacing: 0) {
                                AppRow(app: app, isLoadingUninstall: isLoadingFiles && selectedApp?.id == app.id) {
                                    // Uninstall action: load files, then show sheet.
                                    isLoadingFiles = true
                                    Task {
                                        associatedFiles = await viewModel.previewUninstall(app: app)
                                        selectedApp = app
                                        isLoadingFiles = false
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: app.installPath)])
                                    } label: {
                                        Label("Show in Finder", systemImage: "folder")
                                    }

                                    Button {
                                        withAnimation { expandedAppId = expandedAppId == app.id ? nil : app.id }
                                    } label: {
                                        Label("Show Related Files", systemImage: "doc.text.magnifyingglass")
                                    }
                                }

                                // Expandable related files view.
                                if expandedAppId == app.id {
                                    RelatedFilesView(app: app)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.loadApplications()
        }
        .sheet(item: $selectedApp) { app in
            UninstallPreviewSheet(
                app: app,
                associatedFiles: associatedFiles,
                onConfirm: {
                    Task {
                        let result = await viewModel.deepUninstall(app: app)
                        selectedApp = nil
                        viewModel.lastUninstallResult = result
                        viewModel.showUninstallResult = true
                    }
                },
                onCancel: {
                    selectedApp = nil
                }
            )
        }
    }
}

/// Expandable view showing all related file paths for an app.
struct RelatedFilesView: View {
    let app: ApplicationItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundStyle(.blue)
                Text("Related Files & Folders")
                    .font(.caption.bold())
                Spacer()
                Text("\(app.associatedPaths.count) paths")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ForEach(Array(app.associatedPaths.enumerated()), id: \.offset) { _, path in
                let exists = FileManager.default.fileExists(atPath: path)
                HStack(spacing: 8) {
                    Image(systemName: exists ? "checkmark.circle.fill" : "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(exists ? .green : .gray)

                    Text(path)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    if exists {
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                        } label: {
                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    } else {
                        Text("Not found")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

/// A row displaying app information with real app icon.
struct AppRow: View {
    let app: ApplicationItem
    var isLoadingUninstall: Bool = false
    let onUninstall: () -> Void

    @State private var isHovering = false

    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Real app icon.
                appIcon
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline)
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("v\(app.version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let lastOpened = app.lastOpened {
                        Text(lastOpened, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(FileSizeFormatter.format(app.size))
                    .font(.body.bold().monospacedDigit())
                    .frame(width: 80, alignment: .trailing)

                if isLoadingUninstall {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 75)
                } else {
                    Button("Uninstall", role: .destructive, action: onUninstall)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .opacity(isHovering ? 1 : 0.6)
                }
            }
        }
        .onHover { isHovering = $0 }
    }

    @ViewBuilder
    private var appIcon: some View {
        let nsImage = NSWorkspace.shared.icon(forFile: app.installPath)
        Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

/// Sheet showing uninstall preview with associated files.
struct UninstallPreviewSheet: View {
    let app: ApplicationItem
    let associatedFiles: [(path: String, size: UInt64, exists: Bool)]
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @State private var isUninstalling = false

    var existingFiles: [(path: String, size: UInt64, exists: Bool)] {
        associatedFiles.filter(\.exists)
    }

    var totalSize: UInt64 {
        existingFiles.reduce(0) { $0 + $1.size } + app.size
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with app info.
            HStack(spacing: 16) {
                let nsImage = NSWorkspace.shared.icon(forFile: app.installPath)
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Uninstall \(app.name)")
                        .font(.title2.bold())
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("v\(app.version)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(20)

            Divider()

            // Files header.
            HStack {
                Text("The following files will be moved to Trash:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(existingFiles.count + 1) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            // File list.
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    // App bundle.
                    FilePathRow(path: app.installPath, size: app.size, exists: true, isAppBundle: true)

                    if !associatedFiles.isEmpty {
                        Divider()
                            .padding(.vertical, 4)

                        Text("Associated Files & Data")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        ForEach(Array(associatedFiles.enumerated()), id: \.offset) { _, file in
                            FilePathRow(path: file.path, size: file.size, exists: file.exists)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .frame(minHeight: 180, maxHeight: 300)

            Divider()

            // Footer.
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total: \(FileSizeFormatter.format(totalSize))")
                        .font(.headline)
                    Text("Files will be moved to Trash for safe recovery")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isUninstalling {
                    ProgressView("Removing…")
                        .controlSize(.small)
                } else {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.cancelAction)

                    Button("Move to Trash") {
                        isUninstalling = true
                        onConfirm()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
        }
        .frame(width: 580, height: 500)
    }
}

struct FilePathRow: View {
    let path: String
    let size: UInt64
    let exists: Bool
    var isAppBundle: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: exists ? "checkmark.circle.fill" : "xmark.circle")
                .font(.caption)
                .foregroundStyle(exists ? .green : .gray)

            if isAppBundle {
                Image(systemName: "app.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            Text(path)
                .font(.caption.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if exists {
                Text(FileSizeFormatter.format(size))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Text("Not found")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
