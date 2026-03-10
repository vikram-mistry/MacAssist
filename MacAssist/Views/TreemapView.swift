// TreemapView.swift
// MacAssist
//
// Created by MacAssist on 2026.

import SwiftUI

/// Interactive treemap visualization for storage analysis.
struct TreemapView: View {
    let rootNode: StorageNode
    let totalSize: UInt64

    @State private var selectedNode: StorageNode?
    @State private var hoveredNode: StorageNode?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Breadcrumb header.
            if let selected = selectedNode {
                HStack {
                    Button {
                        selectedNode = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(.plain)

                    Text(selected.name)
                        .font(.headline)

                    Spacer()

                    Text(FileSizeFormatter.format(selected.size))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            // Treemap grid.
            GeometryReader { geometry in
                let nodes = displayNodes
                TreemapLayout(
                    nodes: nodes,
                    totalSize: nodes.reduce(0) { $0 + $1.size },
                    frame: geometry.size
                )
            }
        }
    }

    private var displayNodes: [StorageNode] {
        if let selected = selectedNode, !selected.children.isEmpty {
            return selected.children
        }
        return rootNode.children
    }
}

/// Lays out treemap cells using a squarified algorithm.
struct TreemapLayout: View {
    let nodes: [StorageNode]
    let totalSize: UInt64
    let frame: CGSize

    private let colors: [Color] = [
        .blue, .purple, .orange, .green, .pink, .cyan, .indigo, .mint, .teal, .yellow
    ]

    var body: some View {
        let rects = calculateRects()

        ZStack(alignment: .topLeading) {
            ForEach(Array(rects.enumerated()), id: \.offset) { index, rect in
                let node = nodes[index]
                TreemapCell(
                    node: node,
                    color: colors[index % colors.count],
                    rect: rect
                )
            }
        }
    }

    /// Simple slice-and-dice layout for treemap cells.
    private func calculateRects() -> [CGRect] {
        guard !nodes.isEmpty, totalSize > 0 else { return [] }

        var rects: [CGRect] = []
        var remainingRect = CGRect(origin: .zero, size: frame)
        var isHorizontal = frame.width >= frame.height

        for (index, node) in nodes.enumerated() {
            let fraction = Double(node.size) / Double(totalSize)
            let isLast = index == nodes.count - 1

            if isLast {
                rects.append(remainingRect)
            } else if isHorizontal {
                let width = remainingRect.width * fraction / remainingFraction(from: index)
                let cellRect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY,
                    width: max(width, 2),
                    height: remainingRect.height
                )
                rects.append(cellRect)
                remainingRect = CGRect(
                    x: remainingRect.minX + width,
                    y: remainingRect.minY,
                    width: remainingRect.width - width,
                    height: remainingRect.height
                )
            } else {
                let height = remainingRect.height * fraction / remainingFraction(from: index)
                let cellRect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY,
                    width: remainingRect.width,
                    height: max(height, 2)
                )
                rects.append(cellRect)
                remainingRect = CGRect(
                    x: remainingRect.minX,
                    y: remainingRect.minY + height,
                    width: remainingRect.width,
                    height: remainingRect.height - height
                )
            }

            isHorizontal.toggle()
        }

        return rects
    }

    private func remainingFraction(from index: Int) -> Double {
        let remaining = nodes[index...].reduce(UInt64(0)) { $0 + $1.size }
        return Double(remaining) / Double(totalSize)
    }
}

/// A single cell in the treemap.
struct TreemapCell: View {
    let node: StorageNode
    let color: Color
    let rect: CGRect

    @State private var isHovering = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(isHovering ? 0.7 : 0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .overlay {
                if rect.width > 60 && rect.height > 40 {
                    VStack(spacing: 2) {
                        Text(node.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Text(FileSizeFormatter.formatCompact(node.size))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(4)
                    .foregroundStyle(.white)
                }
            }
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .onHover { isHovering = $0 }
            .help("\(node.name) — \(FileSizeFormatter.format(node.size))")
    }
}
