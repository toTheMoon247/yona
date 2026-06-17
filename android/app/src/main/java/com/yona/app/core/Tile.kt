package com.yona.app.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.text.NumberFormat

/**
 * A saved online account/service (a row in the `tiles` table). Renewal fields are
 * added in a later phase.
 */
@Serializable
data class Tile(
    val id: String,
    val title: String,
    val url: String,
    @SerialName("logo_url") val logoUrl: String? = null,
    val notes: String? = null,
    @SerialName("cost_amount")
    @Serializable(with = FlexibleDoubleSerializer::class)
    val costAmount: Double? = null,
    @SerialName("cost_period") val costPeriod: String? = null,
    @SerialName("created_at") val createdAt: String,
) {
    /** First letter of the title for the placeholder logo. */
    val initial: String get() = title.trim().firstOrNull()?.uppercase() ?: "?"

    val hasNotes: Boolean get() = !notes.isNullOrBlank()

    /** Cost normalized to a monthly figure (yearly ÷ 12); null if no cost. */
    val monthlyCost: Double? get() {
        val amount = costAmount ?: return null
        return if (costPeriod == CostPeriod.YEARLY) amount / 12.0 else amount
    }

    /** Display string like "$15.00 / month", or null if no cost set. */
    val formattedCost: String? get() {
        val amount = costAmount ?: return null
        val period = costPeriod ?: return null
        val unit = if (period == CostPeriod.YEARLY) "year" else "month"
        return "${formatCurrency(amount)} / $unit"
    }
}

object CostPeriod {
    const val MONTHLY = "monthly"
    const val YEARLY = "yearly"
}

/** Formats an amount in the device's locale currency, e.g. "$15.00". */
fun formatCurrency(amount: Double): String = NumberFormat.getCurrencyInstance().format(amount)
