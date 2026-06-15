package com.yona.app.core

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/**
 * Holds the Home tile list as an explicit [LoadState] so the UI renders
 * loading / empty / loaded / error. Mirrors the iOS TileStore.
 */
object TileStore {
    var tiles by mutableStateOf<LoadState<List<Tile>>>(LoadState.Idle)
        private set

    suspend fun load() {
        tiles = LoadState.Loading
        tiles = runCatching { TileRepository.fetchTiles() }.fold(
            onSuccess = { LoadState.Loaded(it) },
            onFailure = { LoadState.Failed(it.message ?: "Couldn't load your accounts.") },
        )
    }

    /** Create a tile, then refresh the list so it appears on Home. */
    suspend fun create(draft: TileDraft): Result<Unit> =
        runCatching { TileRepository.createTile(draft) }
            .onSuccess { load() }
            .map { }
}
