package com.yona.app.core

import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.Serializable

/**
 * Reads/writes tiles via Supabase Postgrest. RLS scopes every query to the signed-in
 * user (`auth.uid()`), so no explicit user filter is needed. Mirrors the iOS
 * SupabaseRepository.
 */
object TileRepository {

    private val columns = Columns.list("id", "title", "url", "logo_url", "notes", "created_at")

    /** All of the current user's tiles, newest first. */
    suspend fun fetchTiles(): List<Tile> =
        Supabase.client.postgrest
            .from("tiles")
            .select(columns) {
                order("created_at", Order.DESCENDING)
            }
            .decodeList<Tile>()

    /** Insert a new tile (user_id defaults to auth.uid()) and return the saved row. */
    suspend fun createTile(draft: TileDraft): Tile =
        Supabase.client.postgrest
            .from("tiles")
            .insert(TileInsert(title = draft.title, url = draft.url, notes = draft.notes)) {
                select(columns)
            }
            .decodeSingle<Tile>()
}

@Serializable
private data class TileInsert(
    val title: String,
    val url: String,
    val notes: String?,
)
