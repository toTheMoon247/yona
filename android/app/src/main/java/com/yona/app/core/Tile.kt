package com.yona.app.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * A saved online account/service (a row in the `tiles` table). Slice A2.1 reads
 * the fields needed for the grid; cost/renewal fields are added in later phases.
 */
@Serializable
data class Tile(
    val id: String,
    val title: String,
    val url: String,
    @SerialName("logo_url") val logoUrl: String? = null,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: String,
) {
    /** First letter of the title for the placeholder logo. */
    val initial: String get() = title.trim().firstOrNull()?.uppercase() ?: "?"

    val hasNotes: Boolean get() = !notes.isNullOrBlank()
}
