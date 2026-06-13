//
//  DesignTokens.swift
//  Yona
//
//  Central spacing / radius / color tokens. Kept small; grows as the UI lands.
//

import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let tile: CGFloat = 20
        static let control: CGFloat = 12
    }

    /// Soft pastel backgrounds behind tiles on the Home grid (from the mockup).
    static let tileBackgrounds: [Color] = [
        Color(red: 0.98, green: 0.92, blue: 0.92), // pink
        Color(red: 0.90, green: 0.94, blue: 0.99), // blue
        Color(red: 0.91, green: 0.96, blue: 0.92), // green
        Color(red: 0.95, green: 0.92, blue: 0.98), // purple
        Color(red: 0.99, green: 0.96, blue: 0.89), // amber
    ]

    /// Saturated colors for the letter-tile (placeholder logo) circle.
    static let letterTileColors: [Color] = [
        .blue, .green, .orange, .pink, .purple, .teal, .indigo, .red,
    ]

    static func tileBackground(for key: String) -> Color {
        tileBackgrounds[stableIndex(key, count: tileBackgrounds.count)]
    }

    static func letterTileColor(for key: String) -> Color {
        letterTileColors[stableIndex(key, count: letterTileColors.count)]
    }

    /// Deterministic index from a key so a tile keeps the same color across
    /// launches (Swift's `hashValue` is per-process-randomized, so we don't use it).
    private static func stableIndex(_ key: String, count: Int) -> Int {
        var hash = 5381
        for byte in key.utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return abs(hash) % max(count, 1)
    }
}
