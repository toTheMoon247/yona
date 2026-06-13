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
}
