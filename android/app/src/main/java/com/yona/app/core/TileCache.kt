package com.yona.app.core

import com.yona.app.YonaApplication
import io.github.jan.supabase.auth.auth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.io.File

/**
 * Per-user on-disk cache of the tile list, so Home renders instantly on cold launch
 * (then refreshes from the network). Mirrors the iOS Codable tile cache.
 */
object TileCache {
    private val json = Json { ignoreUnknownKeys = true }
    private val serializer = ListSerializer(Tile.serializer())

    private fun cacheFile(): File? {
        val userId = Supabase.client.auth.currentUserOrNull()?.id ?: return null
        return File(YonaApplication.instance.filesDir, "tiles-$userId.json")
    }

    suspend fun read(): List<Tile>? = withContext(Dispatchers.IO) {
        val file = cacheFile() ?: return@withContext null
        if (!file.exists()) return@withContext null
        runCatching { json.decodeFromString(serializer, file.readText()) }.getOrNull()
    }

    suspend fun write(tiles: List<Tile>) {
        withContext(Dispatchers.IO) {
            val file = cacheFile() ?: return@withContext
            runCatching { file.writeText(json.encodeToString(serializer, tiles)) }
        }
    }

    suspend fun clear() {
        withContext(Dispatchers.IO) {
            cacheFile()?.delete()
        }
    }
}
