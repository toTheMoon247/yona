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
    @Environment(EntitlementStore.self) private var entitlement

    @AppStorage("tileSort") private var sortOption: TileSort = .recentlyAdded
    @AppStorage("spendShowsMonthly") private var spendShowsMonthly = false
    @State private var searchText = ""
    @State private var showingCreate = false
    @State private var showingPaywall = false
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
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
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
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundStyle(.tint)
                                .font(.subheadline)
                            Text("Yona: Subscription Tracker")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            if !entitlement.isPremium {
                                Button {
                                    showingPaywall = true
                                } label: {
                                    Label("Upgrade to Premium", systemImage: "sparkles")
                                }
                            }
                            #if DEBUG
                            Button("Dev: \(entitlement.isPremium ? "Disable" : "Enable") Premium") {
                                entitlement.setDevPremium(!entitlement.isPremium)
                            }
                            #endif
                            Button("Sign out", role: .destructive) {
                                Task { await auth.signOut() }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .task { await tileStore.load() }
                .sheet(isPresented: $showingPaywall) {
                    PaywallView()
                }
                .sheet(isPresented: $showingCreate) {
                    AddTileFlow()
                }
                .sheet(item: $editingTile) { tile in
                    TileFormSheet(tile: tile)
                }
                .confirmationDialog(
                    "Delete this subscription?",
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
            spendHeader
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

    /// Spend hero: the exact total across all subscriptions, shown per year (monthly × 12
    /// + yearly) or per month (that annual figure ÷ 12), toggled and remembered. Computed
    /// over all subscriptions so it's stable while searching.
    private var spendHeader: some View {
        let items = tileStore.tiles.value ?? []
        let code = Tile.currencyCode

        let annualTotal = items.compactMap(\.annualizedCost).reduce(0, +)
        let displayTotal = spendShowsMonthly ? annualTotal / 12 : annualTotal
        let unit = spendShowsMonthly ? " a month" : " a year"

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            if annualTotal > 0 {
                Text("You pay")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                (
                    Text(displayTotal.formatted(.currency(code: code)))
                        .font(.largeTitle.bold())
                    + Text(unit)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                )
                .contentTransition(.numericText())
                Picker("Show spending per", selection: $spendShowsMonthly) {
                    Text("Monthly").tag(true)
                    Text("Yearly").tag(false)
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .padding(.top, DesignTokens.Spacing.xs)
            } else {
                Text("\(items.count) subscription\(items.count == 1 ? "" : "s")")
                    .font(.largeTitle.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignTokens.Spacing.l)
        .padding(.top, DesignTokens.Spacing.s)
        .padding(.bottom, DesignTokens.Spacing.xs)
        .animation(.snappy, value: spendShowsMonthly)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No subscriptions yet", systemImage: "square.grid.2x2")
        } description: {
            Text("Tap + to add your first subscription.")
        }
    }

    private var errorState: some View {
        ContentUnavailableView {
            Label("Couldn't load your subscriptions", systemImage: "exclamationmark.triangle")
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
            let count = tileStore.tiles.value?.count ?? 0
            if entitlement.canAddTile(currentCount: count) {
                showingCreate = true
            } else {
                showingPaywall = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
                .shadow(radius: 4, y: 2)
        }
        .padding(DesignTokens.Spacing.l)
        .accessibilityLabel("Add subscription")
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }
}
