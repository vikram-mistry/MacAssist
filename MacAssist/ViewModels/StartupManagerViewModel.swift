// StartupManagerViewModel.swift
// MacAssist

import Foundation
import OSLog

@Observable @MainActor
final class StartupManagerViewModel {
    private let launchAgentService = LaunchAgentService()
    private let loginItemsService = LoginItemsService()

    var launchAgents: [LaunchAgentItem] = []
    var loginItems: [LoginItem] = []
    var isLoading = false
    var statusMessage = "Loading startup items…"

    var userAgents: [LaunchAgentItem] { launchAgents.filter { $0.kind == .userAgent } }
    var systemAgents: [LaunchAgentItem] { launchAgents.filter { $0.kind == .systemAgent } }
    var systemDaemons: [LaunchAgentItem] { launchAgents.filter { $0.kind == .systemDaemon } }

    func loadAll() async {
        isLoading = true; statusMessage = "Discovering startup items…"
        launchAgents = await launchAgentService.discoverAll()
        loginItems = await loginItemsService.discoverLoginItems()
        isLoading = false
        statusMessage = "\(launchAgents.count) launch agents, \(loginItems.count) login items"
    }

    func disableAgent(_ agent: LaunchAgentItem) async {
        let success = await launchAgentService.unload(item: agent)
        if success, let index = launchAgents.firstIndex(where: { $0.id == agent.id }) {
            launchAgents[index].status = .unloaded
            statusMessage = "Disabled \(agent.label)"
        }
    }

    func enableAgent(_ agent: LaunchAgentItem) async {
        let success = await launchAgentService.load(item: agent)
        if success, let index = launchAgents.firstIndex(where: { $0.id == agent.id }) {
            launchAgents[index].status = .loaded
            statusMessage = "Enabled \(agent.label)"
        }
    }

    func removeAgent(_ agent: LaunchAgentItem) async {
        let success = await launchAgentService.remove(item: agent)
        if success {
            launchAgents.removeAll { $0.id == agent.id }
            statusMessage = "Removed \(agent.label)"
        }
    }

    func toggleLoginItem(_ item: LoginItem) {
        let success: Bool
        if item.isEnabled {
            success = loginItemsService.disableLoginItem(
                plistPath: item.plistPath,
                bundleIdentifier: item.bundleIdentifier
            )
        } else {
            success = loginItemsService.enableLoginItem(
                plistPath: item.plistPath,
                bundleIdentifier: item.bundleIdentifier
            )
        }

        if success {
            if let index = loginItems.firstIndex(where: { $0.id == item.id }) {
                loginItems[index].isEnabled.toggle()
            }
            statusMessage = item.isEnabled ? "Disabled \(item.name)" : "Enabled \(item.name)"
        } else {
            statusMessage = "Failed to toggle \(item.name). Try running MacAssist with admin privileges."
        }
    }
}
