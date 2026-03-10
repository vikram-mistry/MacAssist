// SidebarView.swift
// MacAssist
//
// Created by MacAssist on 2026.

import SwiftUI

/// Navigation sidebar with section icons following macOS 26 Liquid Glass style.
struct SidebarView: View {
    @Binding var selectedSection: SidebarSection

    var body: some View {
        List(SidebarSection.allCases, selection: $selectedSection) { section in
            Label(section.title, systemImage: section.icon)
                .font(.body)
                .tag(section)
        }
        .listStyle(.sidebar)
        .navigationTitle("MacAssist")
    }
}

/// Sidebar navigation sections.
enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case fileOrganiser = "fileOrganiser"
    case smartClean = "smartClean"
    case junkCleaner = "junkCleaner"
    case storageAnalyzer = "storageAnalyzer"
    case applications = "applications"
    case startupItems = "startupItems"
    case duplicateFinder = "duplicateFinder"
    case settings = "settings"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .fileOrganiser: return "File Organiser"
        case .smartClean: return "Smart Clean"
        case .junkCleaner: return "Junk Cleaner"
        case .storageAnalyzer: return "Storage Analyzer"
        case .applications: return "Applications"
        case .startupItems: return "Startup Items"
        case .duplicateFinder: return "Duplicate Finder"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.bottom.50percent"
        case .fileOrganiser: return "folder.badge.gearshape"
        case .smartClean: return "sparkles"
        case .junkCleaner: return "trash.circle"
        case .storageAnalyzer: return "chart.pie"
        case .applications: return "app.badge.checkmark"
        case .startupItems: return "bolt.circle"
        case .duplicateFinder: return "doc.on.doc"
        case .settings: return "gearshape"
        }
    }
}
