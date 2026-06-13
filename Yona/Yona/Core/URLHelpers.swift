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

    /// The host of a URL, lowercased and without a leading `www.` — e.g.
    /// `https://www.netflix.com/browse` → `netflix.com`. Used as the logo lookup
    /// key (Brandfetch). Returns nil when there's no parseable host.
    static func domain(from raw: String) -> String? {
        guard let host = URL(string: normalized(raw))?.host()?.lowercased(),
              !host.isEmpty else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
