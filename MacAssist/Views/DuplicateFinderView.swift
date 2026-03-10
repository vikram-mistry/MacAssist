// DuplicateFinderView.swift
// MacAssist

import SwiftUI
import AppKit

/// Duplicate File Finder view with folder-wise grouping, multi-select, and batch operations.
struct DuplicateFinderView: View {
    @State private var viewModel = DuplicateFinderViewModel()
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header.
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duplicate Finder")
                        .font(.largeTitle.bold())
                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.hasResults {
                    HStack(spacing: 12) {
                        Button("Auto Select Duplicates") {
                            viewModel.autoSelectDuplicates()
                        }
                        .buttonStyle(.bordered)

                        Button("Deselect All") {
                            viewModel.deselectAll()
                        }
                        .buttonStyle(.bordered)

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Selected", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(viewModel.selectedCount == 0)
                    }
                }
            }
            .padding()

            if viewModel.isScanning || viewModel.isDeleting {
                Spacer()
                ScanProgressView(progress: viewModel.progress, statusMessage: viewModel.statusMessage)
                Spacer()
            } else if viewModel.hasResults {
                // Summary bar.
                HStack(spacing: 24) {
                    Label("\(viewModel.duplicateGroups.count) groups", systemImage: "doc.on.doc")
                    Label("\(viewModel.totalDuplicates) duplicates", systemImage: "doc.on.doc.fill")
                    Label(FileSizeFormatter.format(viewModel.totalWastedSpace) + " wasted", systemImage: "exclamationmark.triangle")

                    Spacer()

                    if viewModel.selectedCount > 0 {
                        Text("\(viewModel.selectedCount) selected · \(FileSizeFormatter.format(viewModel.selectedSize))")
                            .font(.subheadline.bold())
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider()

                // Results list — using index-based ForEach for proper @Observable tracking.
                duplicateGroupsList
            } else {
                // Ready state.
                Spacer()
                EmptyStateView(
                    icon: "doc.on.doc.fill",
                    title: "Find Duplicate Files",
                    description: "Scan a folder to find duplicate files. Files are compared by content hash, not just name.",
                    buttonTitle: "Start Scan",
                    buttonIcon: "magnifyingglass",
                    showFolderPicker: true,
                    selectedPath: $viewModel.scanPath
                ) {
                    Task { await viewModel.scan() }
                }
                Spacer()
            }
        }
        .alert("Delete Duplicates", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                Task { await viewModel.deleteSelected() }
            }
        } message: {
            Text("Move \(viewModel.selectedCount) duplicate files (\(FileSizeFormatter.format(viewModel.selectedSize))) to Trash?")
        }
        .alert("Delete Complete", isPresented: $viewModel.showDeleteResult) {
            Button("OK") { viewModel.showDeleteResult = false }
        } message: {
            Text(viewModel.deleteResultMessage)
        }
    }

    // MARK: - Results List (index-based for proper re-rendering)

    private var duplicateGroupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.duplicateGroups.indices, id: \.self) { groupIndex in
                    let group = viewModel.duplicateGroups[groupIndex]

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            // Group header.
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundStyle(.blue)
                                Text("\(group.count) copies")
                                    .font(.headline)
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text(FileSizeFormatter.format(group.fileSize) + " each")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("Wasted: \(FileSizeFormatter.format(group.wastedSpace))")
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(.red.opacity(0.15)))
                            }

                            Divider()

                            // Files — index-based for @Observable tracking.
                            let oldestId = group.files.min(by: {
                                ($0.modificationDate ?? .distantPast) < ($1.modificationDate ?? .distantPast)
                            })?.id

                            ForEach(viewModel.duplicateGroups[groupIndex].files.indices, id: \.self) { fileIndex in
                                let file = viewModel.duplicateGroups[groupIndex].files[fileIndex]
                                DuplicateFileRow(
                                    file: file,
                                    isOriginal: file.id == oldestId,
                                    onToggle: { viewModel.toggleFile(file.id) }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

/// A row representing a single duplicate file.
struct DuplicateFileRow: View {
    let file: DuplicateFileItem
    let isOriginal: Bool
    let onToggle: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox.
            Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(file.isSelected ? .blue : .secondary)
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggle)

            // File icon.
            fileIcon

            // File info.
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.name)
                        .font(.body)
                        .lineLimit(1)

                    if isOriginal {
                        Text("ORIGINAL")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.green.opacity(0.2)))
                            .foregroundStyle(.green)
                    }
                }

                Text(file.folderPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Modification date.
            if let date = file.modificationDate {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 80, alignment: .trailing)
            }

            // Size.
            Text(FileSizeFormatter.format(file.size))
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.primary.opacity(0.04) : Color.clear)
        )
        .onHover { isHovering = $0 }
        .contextMenu {
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.path)])
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }
            Button {
                let url = URL(fileURLWithPath: file.path)
                NSWorkspace.shared.open(url)
            } label: {
                Label("Open File", systemImage: "eye")
            }
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(file.path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }
        }
    }

    @ViewBuilder
    private var fileIcon: some View {
        let ext = (file.name as NSString).pathExtension.lowercased()
        let iconName: String = {
            switch ext {
            case "jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp", "webp":
                return "photo"
            case "mp4", "mov", "avi", "mkv", "m4v":
                return "film"
            case "mp3", "m4a", "wav", "aac", "flac":
                return "music.note"
            case "pdf":
                return "doc.richtext"
            case "zip", "tar", "gz", "rar", "7z":
                return "archivebox"
            case "dmg":
                return "externaldrive"
            case "app":
                return "app"
            default:
                return "doc"
            }
        }()

        Image(systemName: iconName)
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(width: 24)
    }
}
