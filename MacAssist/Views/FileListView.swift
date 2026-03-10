// FileListView.swift
// MacAssist
//
// Created by MacAssist on 2026.

import SwiftUI
import AppKit

/// Sortable file list view for displaying junk items or large files.
struct FileListView: View {
    let items: [JunkItem]
    let onToggle: (UUID) -> Void

    @State private var sortKey: SortKey = .size
    @State private var ascending = false

    enum SortKey: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case category = "Category"
    }

    var sortedItems: [JunkItem] {
        let sorted: [JunkItem]
        switch sortKey {
        case .name:
            sorted = items.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .size:
            sorted = items.sorted { $0.size > $1.size }
        case .category:
            sorted = items.sorted { $0.category.rawValue < $1.category.rawValue }
        }
        return ascending ? sorted.reversed() : sorted
    }

    var body: some View {
        VStack(spacing: 0) {
            // Sort header.
            HStack {
                ForEach(SortKey.allCases, id: \.self) { key in
                    Button {
                        if sortKey == key {
                            ascending.toggle()
                        } else {
                            sortKey = key
                            ascending = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(key.rawValue)
                                .font(.caption)
                                .fontWeight(sortKey == key ? .bold : .regular)
                            if sortKey == key {
                                Image(systemName: ascending ? "chevron.up" : "chevron.down")
                                    .font(.caption2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(sortKey == key ? .primary : .secondary)

                    if key != SortKey.allCases.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // File list.
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(sortedItems) { item in
                        FileListRow(item: item, onToggle: onToggle)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

/// A single row in the file list.
struct FileListRow: View {
    let item: JunkItem
    let onToggle: (UUID) -> Void

    @State private var isHovering = false
    @State private var showingInfo = false

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox.
            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(item.isSelected ? .blue : .secondary)
                .onTapGesture { onToggle(item.id) }

            // File icon.
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .font(.title3)
                .foregroundStyle(iconColor)

            // File info.
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)

                Text(item.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            
            // Category badge.
            Text(item.category.rawValue)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(categoryColor.opacity(0.2))
                )
                .foregroundStyle(categoryColor)

            // Size.
            Text(FileSizeFormatter.format(item.size))
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
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

    private var iconColor: Color {
        switch item.category {
        case .caches: return .orange
        case .logs: return .blue
        case .temporary: return .gray
        case .developer: return .purple
        case .trash: return .red
        default: return .secondary
        }
    }

    private var categoryColor: Color {
        switch item.severity {
        case .safe: return .green
        case .caution: return .orange
        case .warning: return .red
        }
    }
}
