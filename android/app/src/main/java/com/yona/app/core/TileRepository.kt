package com.yona.app.core

import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order

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
}
