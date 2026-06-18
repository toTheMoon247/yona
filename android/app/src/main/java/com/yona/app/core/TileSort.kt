package com.yona.app.core

import java.time.LocalDate

/** Home grid sort options (mirrors the iOS TileSort). */
enum class TileSort(val label: String) {
    RECENT("Recently added"),
    DUE_DATE("Due date"),
    NAME("Name"),
    COST("Cost");

    fun sorted(tiles: List<Tile>): List<Tile> = when (this) {
        // createdAt is an ISO timestamp string, so lexicographic order is chronological.
        RECENT -> tiles.sortedByDescending { it.createdAt }
        // Soonest renewal first; tiles without a renewal date go last.
        DUE_DATE -> tiles.sortedWith(compareBy(nullsLast<LocalDate>()) { it.nextRenewal })
        NAME -> tiles.sortedBy { it.title.lowercase() }
        // Highest monthly cost first; no-cost tiles last.
        COST -> tiles.sortedByDescending { it.monthlyCost ?: Double.NEGATIVE_INFINITY }
    }
}
