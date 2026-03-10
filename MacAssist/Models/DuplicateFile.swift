// DuplicateFile.swift
// MacAssist

import Foundation

/// A group of duplicate files sharing the same hash and size.
struct DuplicateGroup: Identifiable, Sendable {
    let id: UUID
    let hash: String
    let fileSize: UInt64
    var files: [DuplicateFileItem]

    init(id: UUID = UUID(), hash: String, fileSize: UInt64, files: [DuplicateFileItem] = []) {
        self.id = id
        self.hash = hash
        self.fileSize = fileSize
        self.files = files
    }

    /// Total wasted space (all duplicates minus one original).
    var wastedSpace: UInt64 {
        files.count > 1 ? fileSize * UInt64(files.count - 1) : 0
    }

    /// Number of files in this group.
    var count: Int { files.count }
}

/// An individual file within a duplicate group.
struct DuplicateFileItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let path: String
    let name: String
    let folderPath: String
    let size: UInt64
    let modificationDate: Date?
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        path: String,
        name: String,
        folderPath: String,
        size: UInt64,
        modificationDate: Date? = nil,
        isSelected: Bool = false
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.folderPath = folderPath
        self.size = size
        self.modificationDate = modificationDate
        self.isSelected = isSelected
    }

    static func == (lhs: DuplicateFileItem, rhs: DuplicateFileItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
