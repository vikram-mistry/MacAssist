// StartupItemsView.swift
// MacAssist

import SwiftUI

struct StartupItemsView: View {
    @State private var viewModel = StartupManagerViewModel()
    @State private var selectedTab: StartupTab = .userAgents

    enum StartupTab: String, CaseIterable {
        case userAgents = "User Agents"
        case systemAgents = "System Agents"
        case systemDaemons = "System Daemons"
        case loginItems = "Login Items"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Startup Items").font(.largeTitle.bold())
                    Text(viewModel.statusMessage).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Picker("Category", selection: $selectedTab) {
                ForEach(StartupTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading…")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        switch selectedTab {
                        case .userAgents: agentsList(viewModel.userAgents)
                        case .systemAgents: agentsList(viewModel.systemAgents)
                        case .systemDaemons: agentsList(viewModel.systemDaemons)
                        case .loginItems: loginItemsList
                        }
                    }
                    .padding()
                }
            }
        }
        .task { await viewModel.loadAll() }
    }

    private func agentsList(_ agents: [LaunchAgentItem]) -> some View {
        Group {
            if agents.isEmpty {
                ContentUnavailableView("No Items", systemImage: "bolt.circle",
                    description: Text("No launch agents found in this category."))
            } else {
                ForEach(agents) { agent in
                    GlassCard {
                        HStack(spacing: 12) {
                            Image(systemName: agent.kind.icon)
                                .font(.title3)
                                .foregroundStyle(agent.status == .running || agent.status == .loaded ? .green : .orange)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(agent.label).font(.body.bold()).lineLimit(1)
                                if let exec = agent.executablePath {
                                    Text(exec).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }

                            Spacer()

                            Text(agent.status.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))

                            Menu {
                                if agent.status == .unloaded || agent.status == .stopped {
                                    Button { Task { await viewModel.enableAgent(agent) } } label: {
                                        Label("Enable", systemImage: "play.circle")
                                    }
                                } else {
                                    Button { Task { await viewModel.disableAgent(agent) } } label: {
                                        Label("Disable", systemImage: "pause.circle")
                                    }
                                }
                                Divider()
                                Button(role: .destructive) {
                                    Task { await viewModel.removeAgent(agent) }
                                } label: { Label("Remove", systemImage: "trash") }
                            } label: {
                                Image(systemName: "ellipsis.circle").font(.title3)
                            }
                            .menuStyle(.borderlessButton)
                            .frame(width: 32)
                        }
                    }
                }
            }
        }
    }

    private var loginItemsList: some View {
        Group {
            if viewModel.loginItems.isEmpty {
                ContentUnavailableView("No Login Items", systemImage: "person.badge.key",
                    description: Text("No login items detected."))
            } else {
                ForEach(viewModel.loginItems) { item in
                    GlassCard {
                        HStack {
                            Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(item.isEnabled ? .green : .gray).font(.title3)
                            VStack(alignment: .leading) {
                                Text(item.name).font(.body.bold())
                                if let path = item.path {
                                    Text(path).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { item.isEnabled },
                                set: { _ in viewModel.toggleLoginItem(item) }
                            )).toggleStyle(.switch)
                        }
                    }
                }
            }
        }
    }
}
