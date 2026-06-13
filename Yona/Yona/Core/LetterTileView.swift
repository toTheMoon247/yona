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

    var body: some View {
        Circle()
            .fill(DesignTokens.letterTileColor(for: seed).gradient)
            .overlay {
                Text(initial)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
    }

    private var initial: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.first.map { String($0).uppercased() } ?? "?"
    }
}
