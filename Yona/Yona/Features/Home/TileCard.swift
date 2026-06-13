//
//  TileCard.swift
//  Yona
//
//  A single tile on the Home grid: a large brand logo with the title beneath it.
//

import SwiftUI

struct TileCard: View {
    let tile: Tile

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.s) {
            // Square logo, inset a little for breathing room.
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    TileLogoView(title: tile.title, seed: tile.id.uuidString, websiteURL: tile.url)
                }
                .padding(.horizontal, DesignTokens.Spacing.l)
                .padding(.top, DesignTokens.Spacing.s)

            Text(tile.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.m)
        .background(
            DesignTokens.tileBackground(for: tile.id.uuidString),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.tile, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tile.hasNotes ? "\(tile.title), has a note" : tile.title)
    }
}
