//
//  HomeView.swift
//  Yona
//
//  The signed-in home: a 2-column grid of the user's tiles with loading / empty
//  / error / no-results states, a search bar (title + URL), the floating "+",
//  and a per-tile ••• menu for edit / delete.
//

import SwiftUI

struct HomeView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(TileStore.self) private var tileStore

    @AppStorage("tileSort") private var sortOption: TileSort = .recentlyAdded
    @State private var searchText = ""
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
                .searchable(text: $searchText, prompt: "Search")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Picker("Sort by", selection: $sortOption) {
                                ForEach(TileSort.allCases) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
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
                    AddTileFlow()
                }
                .sheet(item: $editingTile) { tile in
                    TileFormSheet(tile: tile)
                }
                .confirmationDialog(
                    "Delete this tile?",
                    isPresented: deleteDialogBinding,
                    presenting: pendingDelete
                ) { tile in
                    Button("Delete \(tile.title)", role: .destructive) {
                        Task { await tileStore.delete(tile); Haptics.success() }
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
            ScrollView {
                LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.l) {
                    ForEach(0..<6, id: \.self) { _ in
                        TileCardSkeleton()
                    }
                }
                .padding(DesignTokens.Spacing.l)
            }
            .disabled(true)

        case let .loaded(items):
            if items.isEmpty {
                emptyState
            } else {
                let results = sortOption.sort(filtered(items))
                if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    grid(results)
                }
            }

        case .failed:
            errorState
        }
    }

    private func grid(_ items: [Tile]) -> some View {
        ScrollView {
            costSummary(items)
            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.l) {
                ForEach(items) { tile in
                    NavigationLink(value: tile) {
                        TileCard(tile: tile)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
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
                    }
                }
            }
            .padding(DesignTokens.Spacing.l)
            .animation(.snappy, value: items)
        }
        .refreshable { await tileStore.load() }
    }

    /// Case- and diacritic-insensitive filter on title + URL.
    private func filtered(_ items: [Tile]) -> [Tile] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return items.filter { tile in
            tile.title.range(of: query, options: options) != nil
                || tile.url.range(of: query, options: options) != nil
        }
    }

    @ViewBuilder
    private func costSummary(_ items: [Tile]) -> some View {
        let total = items.compactMap(\.monthlyCost).reduce(0, +)
        let count = items.filter { $0.monthlyCost != nil }.count
        if total > 0 {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "creditcard")
                Text("≈ \(total.formatted(.currency(code: Tile.currencyCode)))/mo")
                    .fontWeight(.medium)
                Text("· \(count) paid")
                Spacer()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, DesignTokens.Spacing.l)
            .padding(.top, DesignTokens.Spacing.s)
        }
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
