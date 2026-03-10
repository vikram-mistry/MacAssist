// SmartCleanView.swift
// MacAssist
//
// Created by MacAssist on 2026.

import SwiftUI
import AppKit

/// Smart Clean view combining all scan types with review and clean actions.
struct SmartCleanView: View {
    @State private var viewModel = SmartCleanViewModel()
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header.
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Smart Clean")
                            .font(.largeTitle.bold())
                        Text("Scan and clean all junk files in one pass")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Scan state.
                if viewModel.isScanning || viewModel.isCleaning {
                    GlassCard {
                        ScanProgressView(
                            progress: viewModel.progress,
                            statusMessage: viewModel.statusMessage
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                } else if viewModel.showSuccess {
                    CleanSuccessView(
                        title: "Smart Clean Complete!",
                        message: "Successfully removed \(viewModel.lastCleanedCount) items and freed up \(FileSizeFormatter.format(viewModel.lastCleanedSize)) of storage space.",
                        iconName: "sparkles"
                    ) {
                        withAnimation { viewModel.showSuccess = false }
                    }
                    .frame(minHeight: 400)
                } else if let result = viewModel.scanResult {
                    // Results.
                    scanResultsView(result)
                } else {
                    // Ready state.
                    readyView
                }
            }
            .padding()
        }
        .alert("Confirm Cleaning", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive) {
                Task { await viewModel.cleanSelected() }
            }
        } message: {
            Text("This will permanently delete \(viewModel.selectedItemCount) items (\(FileSizeFormatter.format(viewModel.selectedSize))). This action cannot be undone.")
        }
    }

    private var readyView: some View {
        EmptyStateView(
            icon: "sparkles",
            title: "Smart Clean",
            description: "Scan caches, logs, temporary files, trash, and application leftovers in one pass.",
            buttonTitle: "Start Scan",
            buttonIcon: "magnifyingglass"
        ) {
            Task { await viewModel.startScan() }
        }
    }

    private func scanResultsView(_ result: ScanResult) -> some View {
        VStack(spacing: 16) {
            // Summary card.
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reclaimable Space")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(FileSizeFormatter.format(result.totalSize))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Button {
                            showConfirmation = true
                        } label: {
                            Label("Clean Selected", systemImage: "trash")
                                .frame(maxWidth: 160)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(viewModel.selectedItemCount == 0)

                        Text("\(viewModel.selectedItemCount) items selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Categories.
            ForEach(result.categories) { category in
                GlassCard {
                    DisclosureGroup {
                        ForEach(category.items) { item in
                            SmartCleanItemRow(item: item) {
                                viewModel.toggleItem(item.id)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .font(.title3)
                                .frame(width: 28)

                            Text(category.name)
                                .font(.headline)

                            Spacer()

                            Text("\(category.items.count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(FileSizeFormatter.format(category.totalSize))
                                .font(.body.bold().monospacedDigit())
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.toggleCategory(category.id) }
                    }
                }
            }
        }
    }
}

/// A row view for Smart Clean items with an info popover showing the deletion reason.
struct SmartCleanItemRow: View {
    let item: JunkItem
    let onToggle: () -> Void
    
    @State private var showingInfo = false
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isSelected ? .blue : .secondary)
                .onTapGesture(perform: onToggle)

            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)
                Text(item.path)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()
            
            // Info button explaining why it's safe to delete.
            Button {
                showingInfo.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingInfo, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                        Text("Safe to Delete")
                            .font(.headline)
                    }
                    Text(item.deletionReason)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(width: 320)
            }

            Text(FileSizeFormatter.format(item.size))
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { isHovering = $0 }
        .contextMenu {
            Button {
                if item.isDirectory {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: item.path)
                } else {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
                }
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }
        }
    }
}
