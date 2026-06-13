//
//  BrandResult.swift
//  Yona
//
//  One result from the Brandfetch Brand Search API.
//

import Foundation

struct BrandResult: Identifiable, Decodable, Hashable {
    let name: String?
    let domain: String
    let icon: String?

    var id: String { domain }

    /// Brand name, or a capitalized fallback derived from the domain.
    var displayName: String {
        if let name, !name.isEmpty { return name }
        let main = domain.split(separator: ".").first.map(String.init) ?? domain
        return main.prefix(1).uppercased() + main.dropFirst()
    }
}
