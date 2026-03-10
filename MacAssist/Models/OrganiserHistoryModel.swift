// OrganiserHistoryModel.swift
// MacAssist

import Foundation

struct OrganisedFile: Codable, Identifiable, Sendable {
    var id = UUID()
    let originalName: String
    let category: String
}

struct OrganiserHistorySession: Codable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let directoryPath: String
    let categoryCounts: [String: Int]
    let organisedFiles: [OrganisedFile]

    init(id: UUID = UUID(), date: Date = Date(), directoryPath: String, categoryCounts: [String: Int], organisedFiles: [OrganisedFile]) {
        self.id = id
        self.date = date
        self.directoryPath = directoryPath
        self.categoryCounts = categoryCounts
        self.organisedFiles = organisedFiles
    }
}
