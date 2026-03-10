// FileOrganiserService.swift
// MacAssist

import Foundation
import OSLog

struct FileCategory: Sendable {
    let name: String
    let extensions: Set<String>
}

@Observable @MainActor
final class FileOrganiserService {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "FileOrganiserService")
    
    // Configurable history store
    private let historyKey = "com.vikram.macassist.organiserHistory"
    
    let categories: [FileCategory] = [
        FileCategory(name: "Documents", extensions: ["pdf", "doc", "docx", "txt", "rtf", "pages", "csv", "xls", "xlsx", "ppt", "pptx", "numbers", "key", "epub", "mobi"]),
        FileCategory(name: "Images", extensions: ["jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp", "webp", "svg", "raw", "psd", "ai", "eps"]),
        FileCategory(name: "Videos", extensions: ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm", "mpeg"]),
        FileCategory(name: "Apps", extensions: ["app", "dmg", "pkg", "apk", "exe", "bat", "appimage"]),
        FileCategory(name: "Archives", extensions: ["zip", "tar", "gz", "rar", "7z", "bz2", "xz"]),
        FileCategory(name: "Dev Files", extensions: ["swift", "py", "js", "html", "css", "java", "c", "cpp", "h", "json", "xml", "sql", "plist", "md", "sh", "storyboard", "xib", "xcworkspace", "xcodeproj", "php", "go", "rb"]),
        FileCategory(name: "Audio", extensions: ["mp3", "wav", "aac", "flac", "m4a", "ogg", "wma", "midi"])
    ]

    func loadHistory() -> [OrganiserHistorySession] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([OrganiserHistorySession].self, from: data) else {
            return []
        }
        return history
    }

    func saveHistory(_ history: [OrganiserHistorySession]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    /// Sorts files into categorical folders, ignoring hidden files/folders. 
    func organiseDirectory(at path: String) async -> OrganiserHistorySession? {
        let fm = FileManager.default
        let rootURL = URL(fileURLWithPath: path)
        
        guard let contents = try? fm.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: [.isHiddenKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return nil
        }
        
        var organisedFiles: [OrganisedFile] = []
        var categoryCounts: [String: Int] = [:]
        
        for fileURL in contents {
            guard let values = try? fileURL.resourceValues(forKeys: [.isHiddenKey, .isDirectoryKey]),
                  values.isHidden != true,
                  values.isDirectory != true else {
                continue
            }
            
            let ext = fileURL.pathExtension.lowercased()
            let filename = fileURL.lastPathComponent
            
            // Exclude .DS_Store explicitly
            if filename == ".DS_Store" { continue }
            
            let categoryName = categories.first(where: { $0.extensions.contains(ext) })?.name ?? "Others"
            
            let targetDirectoryURL = rootURL.appendingPathComponent(categoryName)
            if !fm.fileExists(atPath: targetDirectoryURL.path) {
                try? fm.createDirectory(at: targetDirectoryURL, withIntermediateDirectories: true)
            }
            
            let targetFileURL = targetDirectoryURL.appendingPathComponent(filename)
            
            do {
                var finalDestURL = targetFileURL
                var counter = 1
                while fm.fileExists(atPath: finalDestURL.path) {
                    let nameTitle = (filename as NSString).deletingPathExtension
                    let newName = "\(nameTitle) (\(counter)).\(ext)"
                    finalDestURL = targetDirectoryURL.appendingPathComponent(newName)
                    counter += 1
                }
                
                try fm.moveItem(at: fileURL, to: finalDestURL)
                
                organisedFiles.append(OrganisedFile(originalName: filename, category: categoryName))
                categoryCounts[categoryName, default: 0] += 1
            } catch {
                Self.logger.error("Failed to move file \(filename): \(error.localizedDescription)")
            }
        }
        
        guard !organisedFiles.isEmpty else { return nil }
        
        let session = OrganiserHistorySession(
            directoryPath: path,
            categoryCounts: categoryCounts,
            organisedFiles: organisedFiles.sorted(by: { $0.originalName < $1.originalName })
        )
        
        var history = loadHistory()
        history.insert(session, at: 0)
        saveHistory(history)
        
        return session
    }
}
