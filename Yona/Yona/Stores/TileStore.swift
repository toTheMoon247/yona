//
//  TileStore.swift
//  Yona
//
//  Owns the tile list for the UI. Slice 1: load + render. Create/update/delete
//  arrive in later Phase 2 slices.
//

import Foundation
import Observation

@MainActor
@Observable
final class TileStore {
    private(set) var tiles: LoadState<[Tile]> = .idle

    private let repository: SupabaseRepository

    init(repository: SupabaseRepository) {
        self.repository = repository
    }

    /// Load the user's tiles. Shows a spinner only on the first load; a refresh
    /// keeps the current list visible (pull-to-refresh has its own indicator).
    func load() async {
        if tiles.value == nil {
            tiles = .loading
        }
        do {
            tiles = .loaded(try await repository.fetchTiles())
        } catch {
            tiles = .failed(error)
        }
    }

    /// Create a tile and prepend it to the list. Throws so the form can surface
    /// the failure and stay open.
    func create(title: String, url: String, notes: String?) async throws {
        let tile = try await repository.createTile(title: title, url: url, notes: notes)
        var current = tiles.value ?? []
        current.insert(tile, at: 0)
        tiles = .loaded(current)
    }
}
