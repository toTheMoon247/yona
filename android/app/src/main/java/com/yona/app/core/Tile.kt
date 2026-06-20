package com.yona.app.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.text.NumberFormat
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale

/**
 * A saved online account/service (a row in the `tiles` table).
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
    @SerialName("renewal_date") val renewalDate: String? = null,
    @SerialName("renewal_repeat") val renewalRepeat: String? = null,
    @SerialName("billing_source") val billingSource: String? = null,
    @SerialName("payment_method") val paymentMethod: String? = null,
    @SerialName("created_at") val createdAt: String,
) {
    /** First letter of the title for the placeholder logo. */
    val initial: String get() = title.trim().firstOrNull()?.uppercase() ?: "?"

    /** Whether this subscription has a website (URL optional since v0.6.1). */
    val hasWebsite: Boolean get() = url.isNotBlank()

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

    private val anchorDate: LocalDate? get() =
        renewalDate?.let { runCatching { LocalDate.parse(it) }.getOrNull() }

    /** The next upcoming renewal: a repeating anchor rolled forward to today or later. */
    val nextRenewal: LocalDate? get() {
        var date = anchorDate ?: return null
        val today = LocalDate.now()
        when (renewalRepeat) {
            RenewalRepeat.MONTHLY -> while (date.isBefore(today)) date = date.plusMonths(1)
            RenewalRepeat.YEARLY -> while (date.isBefore(today)) date = date.plusYears(1)
            else -> return date
        }
        return date
    }

    /** Whole days from today until the next renewal (negative if past); null if unset. */
    val daysUntilRenewal: Long? get() {
        val next = nextRenewal ?: return null
        return ChronoUnit.DAYS.between(LocalDate.now(), next)
    }

    /** Relative phrase: "today", "tomorrow", "in 12 days", "3 days ago". */
    val renewalRelative: String? get() {
        val days = daysUntilRenewal ?: return null
        return when {
            days == 0L -> "today"
            days == 1L -> "tomorrow"
            days == -1L -> "yesterday"
            days > 0 -> "in $days days"
            else -> "${-days} days ago"
        }
    }

    /** e.g. "Jul 15, 2026 · in 12 days"; null if unset. */
    val renewalSummary: String? get() {
        val next = nextRenewal ?: return null
        val dateStr = next.format(renewalDisplayFormatter)
        val relative = renewalRelative ?: return dateStr
        return "$dateStr · $relative"
    }
}

object CostPeriod {
    const val MONTHLY = "monthly"
    const val YEARLY = "yearly"
}

object RenewalRepeat {
    const val MONTHLY = "monthly"
    const val YEARLY = "yearly"
}

/**
 * Where a subscription is billed — the lead "how it's paid" fact (it says where to
 * cancel/manage it). Stored as the snake_case [raw] string in Postgres. Mirrors iOS.
 */
enum class BillingSource(val raw: String, val label: String) {
    APP_STORE("app_store", "App Store"),
    GOOGLE_PLAY("google_play", "Google Play"),
    DIRECT("direct", "Direct (website)"),
    BANK("bank", "Bank debit"),
    OTHER("other", "Other"),
    ;

    /** Store-billed sources charge the store account, so a per-sub payment method doesn't apply. */
    val usesPaymentMethod: Boolean get() = this != APP_STORE && this != GOOGLE_PLAY

    companion object {
        fun fromRaw(raw: String?): BillingSource? = entries.firstOrNull { it.raw == raw }
    }
}

/** Formats an amount in the device's locale currency, e.g. "$15.00". */
fun formatCurrency(amount: Double): String = NumberFormat.getCurrencyInstance().format(amount)

private val renewalDisplayFormatter: DateTimeFormatter =
    DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.getDefault())
