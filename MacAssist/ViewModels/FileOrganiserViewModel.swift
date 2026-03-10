// FileOrganiserViewModel.swift
// MacAssist

import Foundation

@Observable @MainActor
final class FileOrganiserViewModel {
    private let organiserService = FileOrganiserService()
    
    var history: [OrganiserHistorySession] = []
    var isOrganising = false
    var statusMessage = "Ready to select a folder"
    var showHistory = false
    var selectedPath: String = ""
    var lastSession: OrganiserHistorySession?
    var showNoFilesAlert = false
    
    init() {
        history = organiserService.loadHistory()
    }
    
    func organiseSelectedFolder() async {
        guard !selectedPath.isEmpty else { return }
        
        isOrganising = true
        statusMessage = "Organizing files..."
        lastSession = nil // Reset last session
        
        if let session = await organiserService.organiseDirectory(at: selectedPath) {
            history.insert(session, at: 0)
            statusMessage = "Ready to select a folder" // Don't show success in top-left small text
            lastSession = session
        } else {
            statusMessage = "Ready to select a folder"
            showNoFilesAlert = true
        }
        
        isOrganising = false
        selectedPath = ""
        
        // Sync history down
        history = organiserService.loadHistory()
    }
    
    func clearHistory() {
        organiserService.clearHistory()
        history = []
    }
}
