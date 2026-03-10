// SignatureMatcher.swift
// MacAssist
//
// Created by MacAssist on 2026.

import Foundation
import OSLog

/// Evaluates files against the junk detection rule database (junk_rules.json).
struct SignatureMatcher: Sendable {
    private static let logger = Logger(subsystem: "com.vikram.macassist", category: "SignatureMatcher")

    struct JunkRuleDatabase: Codable {
        let version: String
        let rules: [JunkRule]
    }

    struct JunkRule: Codable, Identifiable {
        let id: String
        let category: String
        let description: String
        let pattern: String
        let severity: String
        let recursive: Bool
    }

    private let rules: [JunkRule]

    init() {
        guard let url = Bundle.main.url(forResource: "junk_rules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let database = try? JSONDecoder().decode(JunkRuleDatabase.self, from: data) else {
            Self.logger.error("Failed to load junk_rules.json")
            self.rules = []
            return
        }
        self.rules = database.rules
    }

    /// Returns all rules.
    var allRules: [JunkRule] {
        rules
    }

    /// Matches a file path against all junk detection rules.
    func matchingRules(for path: String) -> [JunkRule] {
        let expandedPath = expandTilde(path)
        return rules.filter { rule in
            let expandedPattern = expandTilde(rule.pattern)
            return matchesGlob(path: expandedPath, pattern: expandedPattern)
        }
    }

    /// Checks if a path matches any junk rule.
    func isJunk(path: String) -> Bool {
        !matchingRules(for: path).isEmpty
    }

    /// Returns the most severe category for a path.
    func category(for path: String) -> JunkCategory? {
        guard let rule = matchingRules(for: path).first else { return nil }
        return JunkCategory(rawValue: rule.category)
    }

    /// Returns the severity for a path.
    func severity(for path: String) -> JunkSeverity {
        guard let rule = matchingRules(for: path).first else { return .safe }
        return JunkSeverity(rawValue: rule.severity) ?? .safe
    }

    // MARK: - Private Helpers

    private func expandTilde(_ path: String) -> String {
        if path.hasPrefix("~/") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return home + path.dropFirst(1)
        }
        return path
    }

    /// Simple glob-style pattern matching.
    private func matchesGlob(path: String, pattern: String) -> Bool {
        // Convert glob to regex-like matching.
        let regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "**", with: "§DOUBLESTAR§")
            .replacingOccurrences(of: "*", with: "[^/]*")
            .replacingOccurrences(of: "§DOUBLESTAR§", with: ".*")

        let regex = try? NSRegularExpression(pattern: "^\(regexPattern)", options: [])
        let range = NSRange(path.startIndex..., in: path)
        return regex?.firstMatch(in: path, options: [], range: range) != nil
    }
}
