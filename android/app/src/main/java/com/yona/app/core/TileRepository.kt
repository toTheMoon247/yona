package com.yona.app.core

import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Reads/writes tiles via Supabase Postgrest. RLS scopes every query to the signed-in
 * user (`auth.uid()`), so no explicit user filter is needed. Mirrors the iOS
 * SupabaseRepository.
 */
object TileRepository {

    private val columns =
        Columns.list("id", "title", "url", "logo_url", "notes", "cost_amount", "cost_period", "created_at")

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
            .insert(TilePayload(draft)) {
                select(columns)
            }
            .decodeSingle<Tile>()

    /** Update a tile and return the refreshed row (updated_at is bumped by a DB trigger). */
    suspend fun updateTile(id: String, draft: TileDraft): Tile =
        Supabase.client.postgrest
            .from("tiles")
            .update(TilePayload(draft)) {
                select(columns)
                filter { eq("id", id) }
            }
            .decodeSingle<Tile>()

    suspend fun deleteTile(id: String) {
        Supabase.client.postgrest
            .from("tiles")
            .delete {
                filter { eq("id", id) }
            }
    }
}

@Serializable
private data class TilePayload(
    val title: String,
    val url: String,
    val notes: String?,
    @SerialName("cost_amount") val costAmount: Double?,
    @SerialName("cost_period") val costPeriod: String?,
) {
    constructor(draft: TileDraft) : this(
        title = draft.title,
        url = draft.url,
        notes = draft.notes,
        costAmount = draft.costAmount,
        costPeriod = draft.costPeriod,
    )
}
