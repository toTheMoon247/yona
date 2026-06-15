package com.yona.app.core

/**
 * The editable fields for creating/updating a tile. Slice A2.2 covers title/url/notes;
 * cost/renewal fields are added in later phases (mirrors the iOS TileDraft).
 */
data class TileDraft(
    val title: String,
    val url: String,
    val notes: String?,
)
