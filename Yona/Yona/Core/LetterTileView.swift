//
//  LetterTileView.swift
//  Yona
//
//  Placeholder "logo" — a colored circle with the title's first letter. Used
//  while a real logo loads and as the final fallback when none is found
//  (real brand logos arrive in Phase 3).
//

import SwiftUI

struct LetterTileView: View {
    let title: String
    /// Stable key (e.g. the tile id) so the color stays consistent.
    let seed: String
    /// For no-website tiles, show the whole title fitted inside the circle instead
    /// of just the first initial (there's no brand logo to stand in for it).
    var usesFullTitle: Bool = false

    var body: some View {
        Circle()
            .fill(DesignTokens.letterTileColor(for: seed).gradient)
            .overlay { label }
    }

    @ViewBuilder
    private var label: some View {
        if usesFullTitle, !trimmedTitle.isEmpty {
            GeometryReader { geo in
                let inset = geo.size.width * 0.16
                Text(trimmedTitle)
                    .font(.system(size: geo.size.width * 0.22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.3)
                    .lineLimit(3)
                    .frame(width: geo.size.width - inset * 2, height: geo.size.height - inset * 2)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        } else {
            Text(initial)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var initial: String {
        trimmedTitle.first.map { String($0).uppercased() } ?? "?"
    }
}
