package com.yona.app.core

import android.content.Context
import com.yona.app.YonaApplication

/** Small persisted UI preferences (SharedPreferences), e.g. the Home sort choice. */
object Settings {
    private const val KEY_SORT = "tile_sort"
    private const val KEY_SPEND_MONTHLY = "spend_shows_monthly"

    private val prefs by lazy {
        YonaApplication.instance.getSharedPreferences("yona_prefs", Context.MODE_PRIVATE)
    }

    var tileSort: TileSort
        get() = prefs.getString(KEY_SORT, null)
            ?.let { runCatching { TileSort.valueOf(it) }.getOrNull() }
            ?: TileSort.RECENT
        set(value) {
            prefs.edit().putString(KEY_SORT, value.name).apply()
        }

    /** Whether the spend hero shows the per-month figure (vs per-year). */
    var spendShowsMonthly: Boolean
        get() = prefs.getBoolean(KEY_SPEND_MONTHLY, false)
        set(value) {
            prefs.edit().putBoolean(KEY_SPEND_MONTHLY, value).apply()
        }
}
