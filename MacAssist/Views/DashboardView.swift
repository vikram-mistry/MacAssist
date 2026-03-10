// DashboardView.swift
// MacAssist
//
// Created by MacAssist on 2026.

import SwiftUI

/// Main dashboard showing system overview, storage usage, and quick actions.
struct DashboardView: View {
    @Binding var selectedSection: SidebarSection
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header.
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.largeTitle.bold())
                        Text("System overview and maintenance status")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Mac-style storage card.
                GlassCard {
                    VStack(spacing: 16) {
                        HStack {
                            Label("Storage", systemImage: "internaldrive")
                                .font(.headline)
                            Spacer()
                            Text(FileSizeFormatter.format(viewModel.totalDiskSpace))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Multi-segment storage bar (Mac-style).
                        macStorageBar

                        // Legend.
                        storageLegend

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Used")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(FileSizeFormatter.format(viewModel.usedSpace))
                                    .font(.title3.bold().monospacedDigit())
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("Available")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(FileSizeFormatter.format(viewModel.availableSpace))
                                    .font(.title3.bold().monospacedDigit())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                // Quick actions grid.
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    QuickActionCard(
                        title: "Scan",
                        subtitle: "Smart scan & clean",
                        icon: "magnifyingglass.circle.fill",
                        color: .blue
                    ) {
                        selectedSection = .smartClean
                    }

                    QuickActionCard(
                        title: "Clean",
                        subtitle: "Remove junk files",
                        icon: "trash.circle.fill",
                        color: .green
                    ) {
                        selectedSection = .junkCleaner
                    }

                    QuickActionCard(
                        title: "Storage",
                        subtitle: "Analyze disk usage",
                        icon: "chart.pie.fill",
                        color: .orange
                    ) {
                        selectedSection = .storageAnalyzer
                    }
                }

                // Quick stats grid.
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(
                        title: "Last Scan",
                        value: viewModel.lastScanDate.map { RelativeDateTimeFormatter().localizedString(for: $0, relativeTo: Date()) } ?? "Never",
                        icon: "clock",
                        color: .blue
                    )

                    StatCard(
                        title: "Total Cleaned",
                        value: FileSizeFormatter.format(viewModel.totalSpaceCleaned),
                        icon: "sparkles",
                        color: .green
                    )

                    StatCard(
                        title: "Disk Usage",
                        value: String(format: "%.0f%%", viewModel.usedPercentage),
                        icon: "chart.pie",
                        color: viewModel.usedPercentage > 80 ? .red : .orange
                    )
                }

                // Recent scans section.
                if !viewModel.recentScans.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Recent Scans", systemImage: "clock.arrow.circlepath")
                                .font(.headline)

                            ForEach(viewModel.recentScans, id: \.id) { scan in
                                HStack {
                                    Text(scan.scanType)
                                        .font(.body)
                                    Spacer()
                                    Text(FileSizeFormatter.format(scan.sizeCleaned))
                                        .font(.body.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Text(scan.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 100, alignment: .trailing)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.loadDashboard()
        }
    }

    // MARK: - Mac-Style Storage Bar

    private var macStorageBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                ForEach(viewModel.storageBreakdown) { category in
                    let fraction = viewModel.totalDiskSpace > 0
                        ? CGFloat(category.size) / CGFloat(viewModel.totalDiskSpace)
                        : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorFor(category.colorName))
                        .frame(width: max(fraction * geometry.size.width, fraction > 0 ? 2 : 0))
                }

                // Available space.
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.15))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(height: 24)
    }

    private var storageLegend: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], alignment: .leading, spacing: 8) {
            ForEach(viewModel.storageBreakdown) { category in
                HStack(spacing: 6) {
                    Circle()
                        .fill(colorFor(category.colorName))
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(category.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(FileSizeFormatter.format(category.size))
                            .font(.caption2.bold().monospacedDigit())
                    }
                }
            }
            // Available.
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Available")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(FileSizeFormatter.format(viewModel.availableSpace))
                        .font(.caption2.bold().monospacedDigit())
                }
            }
        }
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        case "pink": return .pink
        case "yellow": return .yellow
        case "green": return .green
        case "orange": return .orange
        case "cyan": return .cyan
        case "gray": return .gray
        default: return .secondary
        }
    }
}

/// Clickable quick action card for dashboard navigation.
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            GlassCard {
                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(color.gradient)

                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

/// Reusable stat card component.
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// Glass-morphism card container for Liquid Glass design.
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
