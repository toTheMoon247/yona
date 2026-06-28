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

    /** Cost annualized (amount × times-per-year) for spend totals; null if no cost. */
    val annualizedCost: Double? get() {
        val amount = costAmount ?: return null
        val period = costPeriod ?: return null
        return amount * CostPeriod.timesPerYear(period)
    }

    /** Cost normalized to a monthly figure for summaries/sorting; null if no cost. */
    val monthlyCost: Double? get() = annualizedCost?.let { it / 12.0 }

    /** Display string like "$15.00 / month" or "$60.00 / 2 months"; null if no cost set. */
    val formattedCost: String? get() {
        val amount = costAmount ?: return null
        val period = costPeriod ?: return null
        return "${formatCurrency(amount)} ${CostPeriod.costSuffix(period)}"
    }

    private val anchorDate: LocalDate? get() =
        renewalDate?.let { runCatching { LocalDate.parse(it) }.getOrNull() }

    /** The next upcoming renewal: a repeating anchor rolled forward to today or later. */
    val nextRenewal: LocalDate? get() {
        var date = anchorDate ?: return null
        val repeat = renewalRepeat ?: return date
        val today = LocalDate.now()
        while (date.isBefore(today)) {
            date = when (repeat) {
                RenewalRepeat.WEEKLY -> date.plusDays(7)
                RenewalRepeat.MONTHLY -> date.plusMonths(1)
                RenewalRepeat.EVERY_TWO_MONTHS -> date.plusMonths(2)
                RenewalRepeat.QUARTERLY -> date.plusMonths(3)
                RenewalRepeat.EVERY_SIX_MONTHS -> date.plusMonths(6)
                RenewalRepeat.YEARLY -> date.plusYears(1)
                else -> return date
            }
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
    const val WEEKLY = "weekly"
    const val MONTHLY = "monthly"
    const val EVERY_TWO_MONTHS = "every_two_months"
    const val QUARTERLY = "quarterly"
    const val EVERY_SIX_MONTHS = "every_six_months"
    const val YEARLY = "yearly"

    /** In picker order. */
    val all = listOf(WEEKLY, MONTHLY, EVERY_TWO_MONTHS, QUARTERLY, EVERY_SIX_MONTHS, YEARLY)

    fun timesPerYear(period: String?): Double = when (period) {
        WEEKLY -> 52.0
        EVERY_TWO_MONTHS -> 6.0
        QUARTERLY -> 4.0
        EVERY_SIX_MONTHS -> 2.0
        YEARLY -> 1.0
        else -> 12.0 // monthly / unknown
    }

    fun label(period: String): String = when (period) {
        WEEKLY -> "Weekly"
        MONTHLY -> "Monthly"
        EVERY_TWO_MONTHS -> "Every 2 months"
        QUARTERLY -> "Quarterly"
        EVERY_SIX_MONTHS -> "Every 6 months"
        YEARLY -> "Yearly"
        else -> period
    }

    fun costSuffix(period: String): String = when (period) {
        WEEKLY -> "/ week"
        MONTHLY -> "/ month"
        EVERY_TWO_MONTHS -> "/ 2 months"
        QUARTERLY -> "/ quarter"
        EVERY_SIX_MONTHS -> "/ 6 months"
        YEARLY -> "/ year"
        else -> ""
    }
}

object RenewalRepeat {
    const val WEEKLY = "weekly"
    const val MONTHLY = "monthly"
    const val EVERY_TWO_MONTHS = "every_two_months"
    const val QUARTERLY = "quarterly"
    const val EVERY_SIX_MONTHS = "every_six_months"
    const val YEARLY = "yearly"

    val all = listOf(WEEKLY, MONTHLY, EVERY_TWO_MONTHS, QUARTERLY, EVERY_SIX_MONTHS, YEARLY)

    fun label(period: String): String = when (period) {
        WEEKLY -> "Weekly"
        MONTHLY -> "Monthly"
        EVERY_TWO_MONTHS -> "Every 2 months"
        QUARTERLY -> "Quarterly"
        EVERY_SIX_MONTHS -> "Every 6 months"
        YEARLY -> "Yearly"
        else -> period
    }
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
