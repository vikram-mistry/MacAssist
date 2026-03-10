// MainWindowView.swift
// MacAssist

import SwiftUI

/// Root view with NavigationSplitView providing sidebar + detail layout.
struct MainWindowView: View {
    @State private var selectedSection: SidebarSection = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
        } detail: {
            VStack(spacing: 0) {
                // App branding bar — larger than page titles.
                HStack(spacing: 10) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("MacAssist")
                        .font(.title.bold())
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)

                Divider()

                // Detail content.
                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("")
        .frame(minWidth: 900, minHeight: 600)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .dashboard:
            DashboardView(selectedSection: $selectedSection)
        case .fileOrganiser:
            FileOrganiserView()
        case .smartClean:
            SmartCleanView()
        case .junkCleaner:
            JunkCleanerView()
        case .storageAnalyzer:
            StorageAnalyzerView()
        case .applications:
            AppManagerView()
        case .startupItems:
            StartupItemsView()
        case .duplicateFinder:
            DuplicateFinderView()
        case .settings:
            SettingsView()
        }
    }
}
