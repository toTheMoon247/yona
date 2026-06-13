//
//  BrandSearch.swift
//  Yona
//
//  Brandfetch Brand Search — match a typed name to brands (name + domain + icon)
//  so the add flow can auto-fill. Uses the same client ID as the Logo API.
//

import Foundation

enum BrandSearch {
    /// Search brands by name. Returns [] when there's no client ID or on any failure.
    static func search(_ query: String) async throws -> [BrandResult] {
        guard let clientID = AppConfig.shared.brandfetchClientID else { return [] }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              !encoded.isEmpty,
              let url = URL(string: "https://api.brandfetch.io/v2/search/\(encoded)?c=\(clientID)") else {
            return []
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return []
        }
        return (try? JSONDecoder().decode([BrandResult].self, from: data)) ?? []
    }
}
