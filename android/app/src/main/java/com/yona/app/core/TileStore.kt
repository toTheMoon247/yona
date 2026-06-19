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
        if (tiles !is LoadState.Loaded) {
            // Render the cached list instantly on cold launch, then refresh below.
            val cached = TileCache.read()
            tiles = when {
                cached != null -> LoadState.Loaded(cached)
                showLoading -> LoadState.Loading
                else -> tiles
            }
        }
        runCatching { TileRepository.fetchTiles() }.fold(
            onSuccess = {
                tiles = LoadState.Loaded(it)
                TileCache.write(it)
            },
            onFailure = { error ->
                // Don't blow away an existing (or cached) list on a silent refresh failure.
                if (tiles !is LoadState.Loaded) {
                    tiles = LoadState.Failed(error.message ?: "Couldn't load your accounts.")
                }
            },
        )
    }

    /** Reset in-memory state (e.g. on sign-out) so the next user doesn't see stale tiles. */
    fun reset() {
        tiles = LoadState.Idle
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

    /** Delete a tile (sweeping its Storage files first), then refresh the list. */
    suspend fun delete(id: String): Result<Unit> =
        runCatching {
            // Best-effort: the row cascade removes attachment rows, not the files.
            runCatching { AttachmentRepository.deleteTileAttachments(id) }
            TileRepository.deleteTile(id)
        }.onSuccess { load(showLoading = false) }
}
