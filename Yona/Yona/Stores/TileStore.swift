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

    /// Update a tile in place. Throws so the form can surface the failure.
    func update(id: UUID, title: String, url: String, notes: String?) async throws {
        let updated = try await repository.updateTile(id: id, title: title, url: url, notes: notes)
        guard var current = tiles.value,
              let index = current.firstIndex(where: { $0.id == id }) else { return }
        current[index] = updated
        tiles = .loaded(current)
    }

    /// Delete a tile. On failure the tile stays in the list so the user can retry.
    func delete(_ tile: Tile) async {
        do {
            try await repository.deleteTile(id: tile.id)
            guard var current = tiles.value else { return }
            current.removeAll { $0.id == tile.id }
            tiles = .loaded(current)
        } catch {
            // Keep the tile on failure.
        }
    }
}
