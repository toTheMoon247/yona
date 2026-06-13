//
//  TileDetailView.swift
//  Yona
//
//  Full view of a tile: logo, title, the site (Open Website), and notes.
//  Edit / delete arrive in Slice 4.
//

import SwiftUI

struct TileDetailView: View {
    let tile: Tile

    @State private var showingSafari = false

    private var websiteURL: URL? {
        URL(string: URLHelpers.normalized(tile.url))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.l) {
                LetterTileView(title: tile.title, seed: tile.id.uuidString)
                    .frame(width: 96, height: 96)
                    .padding(.top, DesignTokens.Spacing.l)

                Text(tile.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(displayHost)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showingSafari = true
                } label: {
                    Label("Open Website", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(websiteURL == nil)
                .padding(.horizontal)

                if tile.hasNotes {
                    notesSection
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle(tile.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSafari) {
            if let websiteURL {
                SafariView(url: websiteURL).ignoresSafeArea()
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Text("Notes")
                .font(.headline)
            Text(tile.notes ?? "")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
        )
    }

    private var displayHost: String {
        guard let host = websiteURL?.host() else { return tile.url }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
