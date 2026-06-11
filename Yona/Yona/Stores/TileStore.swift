//
//  TileStore.swift
//  Yona
//
//  Owns the tile list for the UI. Skeleton for Phase 0; fetch/create/update/
//  delete/search are implemented in Phase 2.
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

    // Phase 2:
    //   func load() async
    //   func create(_ draft: TileDraft) async
    //   func update(_ tile: Tile) async
    //   func delete(_ tile: Tile) async
}
