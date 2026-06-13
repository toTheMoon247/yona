//
//  TileStore.swift
//  Yona
//
//  Owns the tile list for the UI: load (cache-first, then network), create,
//  update, delete. Mutations keep an on-disk per-user cache in sync so the grid
//  appears instantly on the next cold launch.
//

import Foundation
import Observation

@MainActor
@Observable
final class TileStore {
    private(set) var tiles: LoadState<[Tile]> = .idle

    private let repository: SupabaseRepository
    private let cache = TileCache()

    init(repository: SupabaseRepository) {
        self.repository = repository
    }

    /// Show cached tiles instantly (first load), then refresh from the network.
    /// On a network failure we keep whatever's already shown rather than blanking.
    func load() async {
        if tiles.value == nil {
            if let userID = repository.currentUserID, let cached = cache.load(userID: userID) {
                tiles = .loaded(cached)
            } else {
                tiles = .loading
            }
        }
        do {
            let fresh = try await repository.fetchTiles()
            tiles = .loaded(fresh)
            persistCache()
        } catch {
            if tiles.value == nil {
                tiles = .failed(error)
            }
        }
    }

    /// Create a tile and prepend it to the list. Throws so the form can surface
    /// the failure and stay open.
    func create(title: String, url: String, notes: String?,
                costAmount: Double?, costPeriod: CostPeriod?) async throws {
        let tile = try await repository.createTile(title: title, url: url, notes: notes,
                                                   costAmount: costAmount, costPeriod: costPeriod)
        var current = tiles.value ?? []
        current.insert(tile, at: 0)
        tiles = .loaded(current)
        persistCache()
    }

    /// Update a tile in place. Throws so the form can surface the failure.
    func update(id: UUID, title: String, url: String, notes: String?,
                costAmount: Double?, costPeriod: CostPeriod?) async throws {
        let updated = try await repository.updateTile(id: id, title: title, url: url, notes: notes,
                                                      costAmount: costAmount, costPeriod: costPeriod)
        guard var current = tiles.value,
              let index = current.firstIndex(where: { $0.id == id }) else { return }
        current[index] = updated
        tiles = .loaded(current)
        persistCache()
    }

    /// Delete a tile. On failure the tile stays in the list so the user can retry.
    func delete(_ tile: Tile) async {
        do {
            try await repository.deleteTile(id: tile.id)
            guard var current = tiles.value else { return }
            current.removeAll { $0.id == tile.id }
            tiles = .loaded(current)
            persistCache()
        } catch {
            // Keep the tile on failure.
        }
    }

    private func persistCache() {
        guard let userID = repository.currentUserID, let items = tiles.value else { return }
        cache.save(items, userID: userID)
    }
}
