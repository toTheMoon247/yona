//
//  TileDetailView.swift
//  Yona
//
//  Full view of a tile: logo, title, the site (Open Website), cost, and notes,
//  plus Edit / Delete. Reads the live tile from the store (by id) so edits
//  reflect immediately and a delete pops back to Home.
//

import SwiftUI

struct TileDetailView: View {
    let tileID: UUID

    @Environment(TileStore.self) private var tileStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingSafari = false
    @State private var editing = false
    @State private var confirmingDelete = false

    private var tile: Tile? {
        tileStore.tiles.value?.first { $0.id == tileID }
    }

    var body: some View {
        Group {
            if let tile {
                detail(tile)
            } else {
                // Tile was deleted — leave the screen.
                Color.clear.onAppear { dismiss() }
            }
        }
    }

    private func detail(_ tile: Tile) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.l) {
                header(tile)
                if tile.hasNotes {
                    notesSection(tile)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .safeAreaInset(edge: .bottom) { createdFooter(tile) }
        .navigationTitle(tile.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar }
        .sheet(isPresented: $showingSafari) {
            if let url = websiteURL(tile) {
                SafariView(url: url).ignoresSafeArea()
            }
        }
        .sheet(isPresented: $editing) {
            TileFormSheet(tile: tile)
        }
        .confirmationDialog("Delete this tile?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) {
                Task {
                    await tileStore.delete(tile)
                    Haptics.success()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\"\(tile.title)\" will be permanently removed.")
        }
    }

    private func header(_ tile: Tile) -> some View {
        VStack(spacing: DesignTokens.Spacing.l) {
            TileLogoView(title: tile.title, seed: tile.id.uuidString, websiteURL: tile.url)
                .frame(width: 96, height: 96)
                .overlay { Circle().strokeBorder(Color(.separator), lineWidth: 1) }
                .padding(.top, DesignTokens.Spacing.l)

            Text(tile.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(displayHost(tile))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let cost = tile.formattedCost {
                Label(cost, systemImage: "creditcard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let renews = tile.renewalSummary {
                Label("Renews \(renews)", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showingSafari = true
            } label: {
                Label("Open Website", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(websiteURL(tile) == nil)
            .padding(.horizontal)
        }
    }

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    editing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func createdFooter(_ tile: Tile) -> some View {
        Text("Tile created \(tile.createdAt.formatted(date: .abbreviated, time: .omitted))")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, DesignTokens.Spacing.s)
    }

    private func notesSection(_ tile: Tile) -> some View {
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

    private func websiteURL(_ tile: Tile) -> URL? {
        URL(string: URLHelpers.normalized(tile.url))
    }

    private func displayHost(_ tile: Tile) -> String {
        guard let host = websiteURL(tile)?.host() else { return tile.url }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
