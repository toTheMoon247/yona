package com.yona.app.core

/**
 * The editable fields for creating/updating a tile (mirrors the iOS TileDraft).
 * Dates are ISO "yyyy-MM-dd" strings, matching the Postgres `date` column.
 */
data class TileDraft(
    val title: String,
    val url: String,
    val notes: String?,
    val costAmount: Double? = null,
    val costPeriod: String? = null,
    val renewalDate: String? = null,
    val renewalRepeat: String? = null,
    val billingSource: String? = null,
    val paymentMethod: String? = null,
)
