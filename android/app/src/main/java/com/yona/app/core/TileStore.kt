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

    /** Load the list. [showLoading] = false keeps the current grid visible (pull-to-refresh). */
    suspend fun load(showLoading: Boolean = true) {
        if (showLoading) tiles = LoadState.Loading
        runCatching { TileRepository.fetchTiles() }.fold(
            onSuccess = { tiles = LoadState.Loaded(it) },
            onFailure = { error ->
                // Don't blow away an existing list on a silent refresh failure.
                if (tiles !is LoadState.Loaded) {
                    tiles = LoadState.Failed(error.message ?: "Couldn't load your accounts.")
                }
            },
        )
    }

    /** Create a tile, then refresh the list so it appears on Home. */
    suspend fun create(draft: TileDraft): Result<Unit> =
        runCatching { TileRepository.createTile(draft) }
            .onSuccess { load(showLoading = false) }
            .map { }

    /** Update a tile, then refresh the list. */
    suspend fun update(id: String, draft: TileDraft): Result<Unit> =
        runCatching { TileRepository.updateTile(id, draft) }
            .onSuccess { load(showLoading = false) }
            .map { }

    /** Delete a tile, then refresh the list. */
    suspend fun delete(id: String): Result<Unit> =
        runCatching { TileRepository.deleteTile(id) }
            .onSuccess { load(showLoading = false) }
}
