// StorageAnalyzerView.swift
// MacAssist

import SwiftUI
import AppKit

/// Storage Analyzer view with treemap, file list, and directory tree display modes.
struct StorageAnalyzerView: View {
    @State private var viewModel = StorageAnalyzerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header.
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storage Analyzer")
                        .font(.largeTitle.bold())
                    Text(viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.storageTree != nil && !viewModel.isAnalyzing {
                    Picker("View", selection: $viewModel.displayMode) {
                        ForEach(StorageAnalyzerViewModel.DisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)

                    Button {
                        Task { await viewModel.analyze() }
                    } label: {
                        Label("Re-Analyze", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()

            if viewModel.isAnalyzing {
                Spacer()
                ScanProgressView(progress: viewModel.progress, statusMessage: viewModel.statusMessage)
                Spacer()
            } else if let tree = viewModel.storageTree {
                switch viewModel.displayMode {
                case .treemap:
                    TreemapView(rootNode: tree, totalSize: tree.size)
                        .padding()

                case .fileList:
                    largeDirectoriesList

                case .directoryTree:
                    directoryTreeView(tree)
                }
            } else {
                Spacer()
                EmptyStateView(
                    icon: "chart.pie.fill",
                    title: "Analyze Storage",
                    description: "Visualize your disk usage with a detailed breakdown by folder and file type.",
                    buttonTitle: "Start Analysis",
                    buttonIcon: "chart.pie"
                ) {
                    Task { await viewModel.analyze() }
                }
                Spacer()
            }
        }
    }

    private var largeDirectoriesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.topDirectories) { node in
                    GlassCard {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading) {
                                Text(node.name)
                                    .font(.body)
                                Text(node.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(FileSizeFormatter.format(node.size))
                                .font(.body.bold().monospacedDigit())
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: node.path)])
                    }
                    .contextMenu {
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: node.path)])
                        } label: {
                            Label("Show in Finder", systemImage: "folder")
                        }
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(node.path, forType: .string)
                        } label: {
                            Label("Copy Path", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            .padding()

            if !viewModel.fileDistribution.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("File Type Distribution")
                            .font(.headline)

                        ForEach(viewModel.fileDistribution.prefix(15)) { dist in
                            HStack {
                                Text(dist.fileType.uppercased())
                                    .font(.caption.bold().monospaced())
                                    .frame(width: 60, alignment: .leading)

                                GeometryReader { geometry in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.blue.opacity(0.6))
                                        .frame(width: geometry.size.width * min(dist.percentage / 100, 1))
                                }
                                .frame(height: 16)

                                Text(String(format: "%.1f%%", dist.percentage))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .trailing)

                                Text(FileSizeFormatter.formatCompact(dist.totalSize))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .trailing)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func directoryTreeView(_ node: StorageNode) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                DirectoryTreeRow(node: node, depth: 0, parentSize: node.size)
            }
            .padding()
        }
    }
}

/// Expandable directory tree row with visual borders and size bar.
struct DirectoryTreeRow: View {
    let node: StorageNode
    let depth: Int
    let parentSize: UInt64

    @State private var isExpanded = false
    @State private var isHovering = false

    private var sizeFraction: CGFloat {
        parentSize > 0 ? CGFloat(node.size) / CGFloat(parentSize) : 0
    }

    private var sizeColor: Color {
        if sizeFraction > 0.5 { return .red }
        if sizeFraction > 0.25 { return .orange }
        if sizeFraction > 0.1 { return .yellow }
        return .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if depth > 0 {
                    Color.clear.frame(width: CGFloat(depth) * 20)
                }

                if node.isDirectory && !node.children.isEmpty {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() } }
                } else {
                    Color.clear.frame(width: 14)
                }

                Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.caption)
                    .foregroundStyle(node.isDirectory ? .blue : .secondary)

                Text(node.name)
                    .font(.body)
                    .lineLimit(1)

                Spacer()

                RoundedRectangle(cornerRadius: 2)
                    .fill(sizeColor.opacity(0.3))
                    .frame(width: max(sizeFraction * 60, 2), height: 10)

                Text(FileSizeFormatter.format(node.size))
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(sizeColor)
                    .frame(width: 75, alignment: .trailing)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.primary.opacity(0.06) : Color.primary.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(isHovering ? 0.12 : 0.05), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isDirectory {
                    withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
                } else {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: node.path)])
                }
            }
            .onHover { isHovering = $0 }
            .contextMenu {
                Button {
                    // Use activateFileViewerSelecting for ALL nodes — works at any depth.
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: node.path)])
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(node.path, forType: .string)
                } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }
            }

            if isExpanded {
                ForEach(node.children.sorted(by: { $0.size > $1.size })) { child in
                    DirectoryTreeRow(node: child, depth: depth + 1, parentSize: node.size)
                }
            }
        }
    }
}
