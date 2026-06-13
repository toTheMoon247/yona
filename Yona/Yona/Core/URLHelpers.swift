//
//  URLHelpers.swift
//  Yona
//

import Foundation

enum URLHelpers {
    /// Light normalization for user-entered URLs: trims whitespace and prepends
    /// `https://` when no scheme is present. (Phase 3 adds domain extraction.)
    static func normalized(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return trimmed
        }
        return "https://" + trimmed
    }
}
