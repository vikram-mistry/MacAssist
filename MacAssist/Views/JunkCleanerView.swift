// JunkCleanerView.swift
// MacAssist
//
// Created by MacAssist on 2026.

import SwiftUI

/// Junk Cleaner view with category filtering and batch operations.
struct JunkCleanerView: View {
    @State private var viewModel = JunkCleanerViewModel()
    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header.
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Junk Cleaner")
                        .font(.largeTitle.bold())
                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !viewModel.junkItems.isEmpty {
                    HStack(spacing: 12) {
                        Button("Select All") { viewModel.selectAll() }
                            .buttonStyle(.bordered)
                        Button("Deselect All") { viewModel.deselectAll() }
                            .buttonStyle(.bordered)

                        Button {
                            showConfirmation = true
                        } label: {
                            Label("Clean", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(viewModel.selectedSize == 0)
                    }
                }
            }
            .padding()

            if viewModel.isScanning {
                Spacer()
                ScanProgressView(progress: 0.5, statusMessage: viewModel.statusMessage)
                Spacer()
            } else if viewModel.showSuccess {
                CleanSuccessView(
                    title: "Junk Cleaned Successfully!",
                    message: "Removed \(viewModel.lastCleanedCount) junk items and reclaimed \(FileSizeFormatter.format(viewModel.lastCleanedSize)) of storage space.",
                    iconName: "trash.circle.fill"
                ) {
                    withAnimation { viewModel.showSuccess = false }
                }
            } else if viewModel.junkItems.isEmpty {
                Spacer()
                EmptyStateView(
                    icon: "sparkles",
                    title: "Junk Cleaner",
                    description: "Scan caches, logs, temporary files, and application leftovers to reclaim disk space.",
                    buttonTitle: "Start Scan",
                    buttonIcon: "magnifyingglass"
                ) {
                    Task { await viewModel.scan() }
                }
                Spacer()
            } else {
                // Category filter bar.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryFilterChip(
                            title: "All",
                            count: viewModel.junkItems.count,
                            size: viewModel.totalJunkSize,
                            isSelected: viewModel.selectedFilter == nil
                        ) {
                            viewModel.selectedFilter = nil
                        }

                        ForEach(viewModel.categorySummary, id: \.category) { summary in
                            CategoryFilterChip(
                                title: summary.category.rawValue,
                                count: summary.count,
                                size: summary.size,
                                isSelected: viewModel.selectedFilter == summary.category
                            ) {
                                viewModel.selectedFilter = viewModel.selectedFilter == summary.category ? nil : summary.category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                Divider()

                // File list.
                FileListView(items: viewModel.filteredItems) { itemId in
                    if let index = viewModel.junkItems.firstIndex(where: { $0.id == itemId }) {
                        viewModel.junkItems[index].isSelected.toggle()
                    }
                }
            }
        }
        .alert("Confirm Cleaning", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive) {
                Task { await viewModel.cleanSelected() }
            }
        } message: {
            Text("Permanently delete \(viewModel.junkItems.filter(\.isSelected).count) items (\(FileSizeFormatter.format(viewModel.selectedSize)))?")
        }
    }
}

/// A filter chip for junk categories.
struct CategoryFilterChip: View {
    let title: String
    let count: Int
    let size: UInt64
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption.bold())
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
