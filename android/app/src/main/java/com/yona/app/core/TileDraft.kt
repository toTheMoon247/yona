package com.yona.app.core

/**
 * The editable fields for creating/updating a tile. Renewal fields are added in a
 * later phase (mirrors the iOS TileDraft).
 */
data class TileDraft(
    val title: String,
    val url: String,
    val notes: String?,
    val costAmount: Double? = null,
    val costPeriod: String? = null,
)
