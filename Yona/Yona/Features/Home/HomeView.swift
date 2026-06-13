//
//  HomeView.swift
//  Yona
//
//  The signed-in home: a 2-column grid of the user's tiles, with loading,
//  empty, and error states, plus the floating "+" to add a tile.
//  Detail / edit / search land in later slices.
//

import SwiftUI

struct HomeView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(TileStore.self) private var tileStore

    @State private var showingCreate = false

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.l),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.l),
    ]

    var body: some View {
        NavigationStack {
            content
                .overlay(alignment: .bottomTrailing) { createButton }
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
                    CreateTileSheet()
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
                    TileCard(tile: tile)
                }
            }
            .padding(DesignTokens.Spacing.l)
        }
        .refreshable { await tileStore.load() }
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
}
