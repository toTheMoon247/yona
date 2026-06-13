//
//  TileCard.swift
//  Yona
//
//  A single tile on the Home grid: placeholder logo, title, and a note indicator.
//

import SwiftUI

struct TileCard: View {
    let tile: Tile

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.s) {
            TileLogoView(title: tile.title, seed: tile.id.uuidString, websiteURL: tile.url)
                .frame(width: 56, height: 56)
                .padding(.top, DesignTokens.Spacing.s)

            Text(tile.title)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.primary)

            // Reserve a constant row so cards line up whether or not they have a note.
            HStack(spacing: DesignTokens.Spacing.xs) {
                if tile.hasNotes {
                    Label("note", systemImage: "note.text")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 16)
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
