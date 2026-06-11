//
//  DesignTokens.swift
//  Yona
//
//  Central spacing / radius / color tokens. Kept tiny for now; grows as the UI lands.
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

    /// Soft pastel backgrounds used behind tiles on the Home grid (from the mockup).
    static let tileBackgrounds: [Color] = [
        Color(red: 0.98, green: 0.92, blue: 0.92), // pink
        Color(red: 0.90, green: 0.94, blue: 0.99), // blue
        Color(red: 0.91, green: 0.96, blue: 0.92), // green
        Color(red: 0.95, green: 0.92, blue: 0.98), // purple
        Color(red: 0.99, green: 0.96, blue: 0.89), // amber
    ]

    /// Deterministic pastel pick for a given key (e.g. tile id) so a tile keeps its color.
    static func tileBackground(for key: some Hashable) -> Color {
        let index = abs(key.hashValue) % tileBackgrounds.count
        return tileBackgrounds[index]
    }
}
