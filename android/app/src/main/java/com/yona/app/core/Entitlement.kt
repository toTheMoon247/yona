package com.yona.app.core

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/**
 * Premium entitlement gate. Yona is free up to [FREE_TILE_LIMIT] subscriptions; adding
 * beyond that needs Premium. Existing subscriptions are grandfathered — the cap only
 * blocks *adding*, never hides/deletes. Mirrors the iOS EntitlementStore.
 *
 * Real billing (Google Play Billing / RevenueCat) isn't wired yet — [setDevPremium] is
 * a debug-only unlock, and server-side enforcement (RLS) comes once products exist.
 */
object Entitlement {
    const val FREE_TILE_LIMIT = 4

    var isPremium by mutableStateOf(false)
        private set

    /** Whether another subscription may be added at the current count. */
    fun canAdd(currentCount: Int): Boolean = isPremium || currentCount < FREE_TILE_LIMIT

    /** Debug-only unlock until real billing is connected. */
    fun setDevPremium(value: Boolean) {
        isPremium = value
    }
}
