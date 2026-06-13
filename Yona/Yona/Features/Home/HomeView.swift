//
//  HomeView.swift
//  Yona
//
//  The signed-in home: a 2-column grid of the user's tiles with loading / empty
//  / error states, the floating "+" to add a tile, and a per-tile ••• menu for
//  edit / delete. Search lands in Slice 5.
//

import SwiftUI

struct HomeView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(TileStore.self) private var tileStore

    @State private var showingCreate = false
    @State private var editingTile: Tile?
    @State private var pendingDelete: Tile?

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.l),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.l),
    ]

    var body: some View {
        NavigationStack {
            content
                .overlay(alignment: .bottomTrailing) { createButton }
                .navigationDestination(for: Tile.self) { tile in
                    TileDetailView(tileID: tile.id)
                }
                .navigationTitle("Yona")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Sign out", role: .destructive) {
                                Task { await auth.signOut() }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .task { await tileStore.load() }
                .sheet(isPresented: $showingCreate) {
                    TileFormSheet(mode: .create)
                }
                .sheet(item: $editingTile) { tile in
                    TileFormSheet(mode: .edit(tile))
                }
                .confirmationDialog(
                    "Delete this tile?",
                    isPresented: deleteDialogBinding,
                    presenting: pendingDelete
                ) { tile in
                    Button("Delete \(tile.title)", role: .destructive) {
                        Task { await tileStore.delete(tile) }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { tile in
                    Text("\"\(tile.title)\" will be permanently removed.")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tileStore.tiles {
        case .idle, .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .loaded(items):
            if items.isEmpty {
                emptyState
            } else {
                grid(items)
            }

        case .failed:
            errorState
        }
    }

    private func grid(_ items: [Tile]) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.l) {
                ForEach(items) { tile in
                    NavigationLink(value: tile) {
                        TileCard(tile: tile)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .topTrailing) { tileMenu(tile) }
                }
            }
            .padding(DesignTokens.Spacing.l)
        }
        .refreshable { await tileStore.load() }
    }

    private func tileMenu(_ tile: Tile) -> some View {
        Menu {
            Button {
                editingTile = tile
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                pendingDelete = tile
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.ultraThinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .padding(DesignTokens.Spacing.s)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No tiles yet", systemImage: "square.grid.2x2")
        } description: {
            Text("Tap + to add your first account.")
        }
    }

    private var errorState: some View {
        ContentUnavailableView {
            Label("Couldn't load your tiles", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Check your connection and try again.")
        } actions: {
            Button("Retry") {
                Task { await tileStore.load() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var createButton: some View {
        Button {
            showingCreate = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
                .shadow(radius: 4, y: 2)
        }
        .padding(DesignTokens.Spacing.l)
        .accessibilityLabel("Add tile")
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }
}
